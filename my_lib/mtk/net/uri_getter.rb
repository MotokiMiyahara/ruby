# vim:set fileencoding=utf-8:

###
require 'open-uri'
require 'openssl'
require 'zlib'
require 'forwardable'
require 'delegate'


module Mtk
  module Net
    class MetaWrapper < SimpleDelegator 
      extend Forwardable
      def_delegators(:@meta_io, *OpenURI::Meta.public_instance_methods(true))

      def initialize decoder, meta_io
        super(decoder)
        @meta_io = meta_io
      end
    end

    module UriGetter
      USER_AGENT_FIREFOX = "Mozilla/5.0 (Windows NT 5.1; rv:21.0) Gecko/20100101 Firefox/21.0"

      class <<self
        public
        def get_binary uri, *rest
          open_uri(uri, "rb", *rest) do |f|
            return f.read
          end
        end

        def get_html_as_utf8(uri, *rest)
          return open_html_uri(uri, *rest).encode('UTF-8', invalid: :replace, undef: :replace)
        end


        private 
        # charsetから戻り値のエンコーディングに反映
        def open_html_uri(uri, *rest)
          open_uri(uri, *rest) do |data|
            text = data.read
            #if equals_encoding(Encoding::ISO_8859_1, data.charset) &&
            if equals_encoding(Encoding::ISO_8859_1, data.charset)
                #enc_str = get_charset_from_html(text)
                #text = text.dup.force_encoding(enc_str)
                change_charset_from_html(text)
            end
            return text
          end
        end

        # デフォルト値を変更したopen
        #def open_uri(name, mode='r', perm=nil, opts={}, &block)
        def open_uri(*args, &block)
          options = {
            'User-Agent' => USER_AGENT_FIREFOX, 
            'Accept-Language' => 'ja,en-us;q=0.7,en;q=0.3',
            :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE,
            'Accept-Encoding' => 'gzip, deflate',
          }
          opts = args[-1].is_a?(Hash) ? args.pop : {}
          options.merge! opts


          #pp opts
          if block.nil?
            meta_io = open(*args, options)
            return wrap_condent_decoder(meta_io)
          elsif
            open(*args, options) do |data|
              block.call(wrap_content_decoder(data))
            end
          end
        end
        
        def wrap_content_decoder meta_io
          content_encoding = meta_io.meta['content-encoding']
          case content_encoding
          when /gzip/i
            decoder = Zlib::GzipReader.new(meta_io,  external_encoding: 'UTF-8')
          when /deflate/i
            decoder = Zlib::Inflate.new
            decoder << meta_io.read
          else
            decoder = nil
          end

          if decoder
            meta_io.meta.delete('content-encoding')
            return MetaWrapper.new(decoder, meta_io)
          else
            return meta_io
          end
        end

        # htmlのメタタグからcharsetを判定し、強制的に変換する
        def change_charset_from_html (text)
          text = text.force_encoding('ASCII-8BIT')
          if text =~ %r{<meta\s+http-equiv\s*=\s*"?Content-Type"?\s+content\s*=\s*"[^">]*charset=([^">]*)">}in || 
              text =~ %r{<meta\s+content\s*=\s*"[^">]*charset=([^">]*)"[^>]*http-equiv\s*=\s*"?Content-Type"?[^>]*>}in
            enc_str = fix_charset($1)
            text.force_encoding(enc_str)
          end
        end
=begin
        # htmlのメタタグからcharsetを取得
        def get_charset_from_html (text)
          #pp text
          
          if text.dup.force_encoding('ASCII-8BIT') =~ %r{<meta\s+http-equiv\s*=\s*"?Content-Type"?\s+content\s*=\s*"[^">]*charset=([^">]*)">}in || 
              text.dup.force_encoding('ASCII-8BIT') =~ %r{<meta\s+content\s*=\s*"[^">]*charset=([^">]*)"[^>]*http-equiv\s*=\s*"?Content-Type"?[^>]*>}in
            return fix_charset($1)
          else
            return nil
          end
        end
=end



        # 非公式なcharsetから公式な形式を得ます
        def fix_charset charset
          fixed_charset = charset.upcase

          table = {'SHIFT_JIS' => ['X-SJIS']
          }

          table.each_pair do |formal, informals|
            return formal if informals.include?(fixed_charset)
          end
          return fixed_charset
        end

        def equals_encoding(encoding, str)
          encoding.names.include? str.upcase
        end

      end
    end
  end
end

