# Source: https://gist.github.com/janko-m/7cd94b8b4dd113c2c193#file-02-safe-download-commented-rb
require "open-uri"
require "net/http" # Just to get the SocketError class

module Box
  module DownloadFile

    Error = Class.new(StandardError)

    DOWNLOAD_ERRORS = [
      SocketError,          # domain not found
      OpenURI::HTTPError,   # response status 4xx or 5xx
      RuntimeError,         # redirection errors (e.g. redirection loop)
      URI::InvalidURIError, # invalid URL
      Error,                # our errors
    ]

    def download(url, max_size: nil)
      # URLs with spaces will raise an InvalidURIError, so we need to encode it.
      # However, the user can pass an already encoded URL, so we first need to
      # decode it.
      url = URI.encode(URI.decode(url))

      # This will raise an InvalidURIError if the URL is very wrong. It will still
      # pass for strings like "foo", though.
      url = URI(url)

      # We need to check if the URL was either http://, https:// or ftp://, because
      # these are the only ones we can download from. open-uri will add the #open
      # method only to these ones, so this is a good check.
      raise Error, "url was invalid" if !url.respond_to?(:open)

      options = {}
      # It was shown that in a random sample approximately 20% of websites will
      # simply refuse a request which doesn't have a valid User-Agent.
      options["User-Agent"] = "MyApp/1.2.3"
      # It's good to shield ourselves from files that are too big. open-uri will
      # call this block as soon as it gets the "Content-Length" header, which means
      # that we can bail out before we download the file.
      options[:content_length_proc] = ->(size) {
        if max_size && size && size > max_size # sometimes "Content-Length" can be empty
          raise Error, "file is too big (max is #{max_size})"
        end
      }

      # Finally we download the file. Here we mustn't use simple #open that open-uri
      # overrides, because this is vulnerable to shell execution attack (if #open
      # method detects a starting pipe (e.g. "| ls"), it will execute the following
      # as a shell command).
      downloaded_file = url.open(options)

      # open-uri will return a StringIO instead of a Tempfile if the filesize
      # is less than 10 KB, so we patch this behaviour by converting it into a
      # Tempfile.
      if downloaded_file.is_a?(StringIO)
        # We need to open it in binary mode for Windows users.
        tempfile = Tempfile.new("open-uri", binmode: true)
        # IO.copy_stream is the most efficient way of data transfer.
        IO.copy_stream(downloaded_file, tempfile.path)
        # We add the metadata that open-uri puts on the file (e.g. #content_type)
        OpenURI::Meta.init tempfile, downloaded_file
        downloaded_file = tempfile
      end

      downloaded_file

    rescue *DOWNLOAD_ERRORS => error
      # open-uri will throw a RuntimeError when it detects a redirection loop, so
      # we want to reraise the exception if it was some other RuntimeError
      raise if error.instance_of?(RuntimeError) && error.message !~ /redirection/
      # We raise our unified Error class
      raise Error, "download failed (#{url}): #{error.message}"
    end
  end
end
