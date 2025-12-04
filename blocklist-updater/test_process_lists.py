import pytest
import os
import tempfile
import re
from unittest.mock import patch, MagicMock
from io import BytesIO

# Import the module under test
import process_lists


class TestDomainRegex:
    """Test the domain regex pattern."""
    
    def test_plain_domain(self):
        """Test plain domain matching."""
        match = process_lists.domain_regex.match('example.com')
        assert match is not None
        assert match.group(1) == 'example.com'
    
    def test_hosts_file_format(self):
        """Test hosts file format (IP + domain)."""
        match = process_lists.domain_regex.match('0.0.0.0 example.com')
        assert match is not None
        assert match.group(1) == 'example.com'
        
        match = process_lists.domain_regex.match('127.0.0.1 localhost')
        assert match is not None
        assert match.group(1) == 'localhost'
    
    def test_subdomain(self):
        """Test subdomain matching."""
        match = process_lists.domain_regex.match('sub.domain.example.com')
        assert match is not None
        assert match.group(1) == 'sub.domain.example.com'
    
    def test_with_comments(self):
        """Test domain with trailing comment."""
        match = process_lists.domain_regex.match('example.com # comment')
        assert match is not None
        assert match.group(1) == 'example.com'
    
    def test_invalid_patterns(self):
        """Test that invalid patterns don't match."""
        assert process_lists.domain_regex.match('') is None
        assert process_lists.domain_regex.match('#comment') is None


class TestFetchAndParseList:
    """Test the fetch_and_parse_list function."""
    
    def setup_method(self):
        """Clear unique_domains before each test."""
        process_lists.unique_domains.clear()
    
    @patch('urllib.request.urlopen')
    def test_plain_domain_list(self, mock_urlopen):
        """Test parsing plain domain list."""
        content = b"example.com\ntest.com\nsub.domain.com\n"
        mock_response = MagicMock()
        mock_response.__enter__ = MagicMock(return_value=BytesIO(content).readlines())
        mock_response.__exit__ = MagicMock(return_value=False)
        mock_urlopen.return_value = mock_response
        
        process_lists.fetch_and_parse_list('http://example.com/list')
        
        assert 'example.com' in process_lists.unique_domains
        assert 'test.com' in process_lists.unique_domains
        assert 'sub.domain.com' in process_lists.unique_domains
        assert len(process_lists.unique_domains) == 3
    
    @patch('urllib.request.urlopen')
    def test_hosts_file_format(self, mock_urlopen):
        """Test parsing hosts file format."""
        content = b"0.0.0.0 example.com\n127.0.0.1 sub.domain.org\n0.0.0.0 test.com\n"
        mock_response = MagicMock()
        mock_response.__enter__ = MagicMock(return_value=BytesIO(content).readlines())
        mock_response.__exit__ = MagicMock(return_value=False)
        mock_urlopen.return_value = mock_response
        
        process_lists.fetch_and_parse_list('http://example.com/hosts')
        
        assert 'example.com' in process_lists.unique_domains
        assert 'sub.domain.org' in process_lists.unique_domains
        assert 'test.com' in process_lists.unique_domains
    
    @patch('urllib.request.urlopen')
    def test_adblock_format(self, mock_urlopen):
        """Test parsing AdBlockPlus format."""
        content = b"||ads.example.com^\n||tracker.com^\n||malware.site^$third-party\n"
        mock_response = MagicMock()
        mock_response.__enter__ = MagicMock(return_value=BytesIO(content).readlines())
        mock_response.__exit__ = MagicMock(return_value=False)
        mock_urlopen.return_value = mock_response
        
        process_lists.fetch_and_parse_list('http://example.com/adblock')
        
        assert 'ads.example.com' in process_lists.unique_domains
        assert 'tracker.com' in process_lists.unique_domains
        assert 'malware.site' in process_lists.unique_domains
    
    @patch('urllib.request.urlopen')
    def test_ignore_comments(self, mock_urlopen):
        """Test that comments are ignored."""
        content = b"# This is a comment\n! Another comment\nexample.com\n// Path comment\n"
        mock_response = MagicMock()
        mock_response.__enter__ = MagicMock(return_value=BytesIO(content).readlines())
        mock_response.__exit__ = MagicMock(return_value=False)
        mock_urlopen.return_value = mock_response
        
        process_lists.fetch_and_parse_list('http://example.com/list')
        
        assert 'example.com' in process_lists.unique_domains
        assert len(process_lists.unique_domains) == 1
    
    @patch('urllib.request.urlopen')
    def test_ignore_abp_special_rules(self, mock_urlopen):
        """Test that ABP special rules are ignored."""
        content = b"[Adblock Plus 2.0]\n@@||whitelist.com^\nexample.com##.ad\ntest.com#@#.element\nvalid.com\n"
        mock_response = MagicMock()
        mock_response.__enter__ = MagicMock(return_value=BytesIO(content).readlines())
        mock_response.__exit__ = MagicMock(return_value=False)
        mock_urlopen.return_value = mock_response
        
        process_lists.fetch_and_parse_list('http://example.com/abp')
        
        assert 'valid.com' in process_lists.unique_domains
        assert 'whitelist.com' not in process_lists.unique_domains
        assert 'example.com' not in process_lists.unique_domains
        assert 'test.com' not in process_lists.unique_domains
    
    @patch('urllib.request.urlopen')
    def test_duplicate_removal(self, mock_urlopen):
        """Test that duplicates are removed."""
        content = b"example.com\nexample.com\nEXAMPLE.COM\n0.0.0.0 example.com\n"
        mock_response = MagicMock()
        mock_response.__enter__ = MagicMock(return_value=BytesIO(content).readlines())
        mock_response.__exit__ = MagicMock(return_value=False)
        mock_urlopen.return_value = mock_response
        
        process_lists.fetch_and_parse_list('http://example.com/list')
        
        assert len(process_lists.unique_domains) == 1
        assert 'example.com' in process_lists.unique_domains
    
    @patch('urllib.request.urlopen')
    def test_invalid_domains_filtered(self, mock_urlopen):
        """Test that invalid domains are filtered out."""
        content = b"*.wildcard.com\n-invalid.com\ninvalid-.com\n0.0.0.0\nnodots\nvalid.com\n"
        mock_response = MagicMock()
        mock_response.__enter__ = MagicMock(return_value=BytesIO(content).readlines())
        mock_response.__exit__ = MagicMock(return_value=False)
        mock_urlopen.return_value = mock_response
        
        process_lists.fetch_and_parse_list('http://example.com/list')
        
        assert 'valid.com' in process_lists.unique_domains
        assert len(process_lists.unique_domains) == 1
    
    @patch('urllib.request.urlopen')
    def test_network_error_handling(self, mock_urlopen):
        """Test that network errors are handled gracefully."""
        import urllib.error
        mock_urlopen.side_effect = urllib.error.URLError('Network error')
        
        # Should not raise an exception
        process_lists.fetch_and_parse_list('http://example.com/list')
        
        assert len(process_lists.unique_domains) == 0


class TestGenerateHostsFile:
    """Test the generate_hosts_file function."""
    
    def setup_method(self):
        """Clear unique_domains before each test."""
        process_lists.unique_domains.clear()
    
    def test_empty_hosts_file(self):
        """Test generating hosts file with no domains."""
        with tempfile.NamedTemporaryFile(mode='r', delete=False) as tmp:
            tmp_path = tmp.name
        
        try:
            process_lists.generate_hosts_file(tmp_path)
            
            with open(tmp_path, 'r') as f:
                content = f.read()
            
            assert '# Last updated (UTC):' in content
            assert '# Generated by' in content
            assert '# Total unique domains: 0' in content
        finally:
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)
    
    def test_hosts_file_with_domains(self):
        """Test generating hosts file with domains."""
        process_lists.unique_domains.add('example.com')
        process_lists.unique_domains.add('test.com')
        process_lists.unique_domains.add('abc.com')
        
        with tempfile.NamedTemporaryFile(mode='r', delete=False) as tmp:
            tmp_path = tmp.name
        
        try:
            process_lists.generate_hosts_file(tmp_path)
            
            with open(tmp_path, 'r') as f:
                content = f.read()
            
            assert '# Total unique domains: 3' in content
            assert '0.0.0.0\tabc.com' in content
            assert '0.0.0.0\texample.com' in content
            assert '0.0.0.0\ttest.com' in content
            
            # Check that domains are sorted
            lines = [line for line in content.split('\n') if line.startswith('0.0.0.0')]
            assert lines[0].endswith('abc.com')
            assert lines[1].endswith('example.com')
            assert lines[2].endswith('test.com')
        finally:
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)
    
    def test_file_permissions(self):
        """Test that the output file has correct permissions."""
        process_lists.unique_domains.add('example.com')
        
        with tempfile.NamedTemporaryFile(mode='r', delete=False) as tmp:
            tmp_path = tmp.name
        
        try:
            process_lists.generate_hosts_file(tmp_path)
            
            # Check file permissions (0o664 = rw-rw-r--)
            stat_info = os.stat(tmp_path)
            perms = stat_info.st_mode & 0o777
            assert perms == 0o664
        finally:
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)


class TestMain:
    """Test the main function."""
    
    def setup_method(self):
        """Clear unique_domains before each test."""
        process_lists.unique_domains.clear()
    
    @patch('sys.argv', ['process_lists.py'])
    def test_main_missing_argument(self):
        """Test that main exits when output path is not provided."""
        with pytest.raises(SystemExit) as exc_info:
            process_lists.main()
        assert exc_info.value.code == 1
    
    @patch('sys.argv', ['process_lists.py', '/tmp/test_output.hosts'])
    @patch('process_lists.fetch_and_parse_list')
    @patch('process_lists.generate_hosts_file')
    def test_main_with_default_url(self, mock_generate, mock_fetch):
        """Test main with default URL when BLOCKLIST_URLS is not set."""
        with patch.dict(os.environ, {}, clear=True):
            process_lists.main()
            
            mock_fetch.assert_called_once()
            assert 'StevenBlack' in mock_fetch.call_args[0][0]
            mock_generate.assert_called_once_with('/tmp/test_output.hosts')
    
    @patch('sys.argv', ['process_lists.py', '/tmp/test_output.hosts'])
    @patch('process_lists.fetch_and_parse_list')
    @patch('process_lists.generate_hosts_file')
    def test_main_with_custom_urls(self, mock_generate, mock_fetch):
        """Test main with custom BLOCKLIST_URLS."""
        test_urls = 'http://example.com/list1 http://example.com/list2'
        with patch.dict(os.environ, {'BLOCKLIST_URLS': test_urls}):
            process_lists.main()
            
            assert mock_fetch.call_count == 2
            mock_generate.assert_called_once_with('/tmp/test_output.hosts')
