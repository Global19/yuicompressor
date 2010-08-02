require 'open3'

module YUICompressor
  module Shell

    # Returns an array of flags that should be passed to the jar file on the
    # command line for the given set of +options+.
    def command_arguments(options={})
      args = []
      args.concat(['--type', options[:type].to_s]) if options[:type]
      args.concat(['--charset', options[:charset].to_s]) if options[:charset]
      args.concat(['--line-break', options[:line_break].to_s]) if options[:line_break]

      if options[:type].to_s == 'js'
        args << '--nomunge' unless options[:munge]
        args << '--preserve-semi' if options[:preserve_semicolons]
        args << '--disable-optimizations' unless options[:optimize]
      end

      args
    end

    # Compresses the given +stream_or_string+ of code using the given +options+.
    # When using this method directly, at least the +:type+ option must be
    # specified, and should be one of +'css'+ or +'js'+. See
    # YUICompressor#compress_css and YUICompressor#compress_js for more details
    # about which options are acceptable for each type of compressor.
    #
    # If a block is given, it will receive the IO output object. Otherwise the
    # output will be returned as a string.
    def compress(stream_or_string, options={})
      raise ArgumentError, 'Option :type required' unless options.key?(:type)

      stream = streamify(stream_or_string)

      case options[:type].to_s
      when 'js'
        options = default_js_options.merge(options)
      when 'css'
        options = default_css_options.merge(options)
      else
        raise ArgumentError, 'Unknown resource type: %s' % options[:type]
      end

      command = [ options.delete(:java) || 'java', '-jar', JAR_FILE ]
      command.concat(command_arguments(options))

      Open3.popen3(*command) do |stdin, stdout, stderr|
        begin
          while buffer = stream.read(4096)
            stdin.write(buffer)
          end

          stdin.close

          if block_given?
            yield stdout
          else
            stdout.read
          end
        rescue Exception => e
          raise RuntimeError, 'Compression failed: %s' % e.message
        end
      end
    end

  end
end
