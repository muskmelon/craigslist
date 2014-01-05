module Craigslist
  module Net

    OPTIONS_PARAMS_MAP = {
      query: :query,
      search_type: :searchType,
      min_ask: :minAsk,
      max_ask: :maxAsk,
      has_image: :hasPic
    }
    
    # Yuan: new method to define a country
    @@country = ''
    def self.country=(country)
      @@country = country
    end
    def self.country
      @@country
    end
    
    class << self
      
      # Yuan: Overwrite to be able to handle multiple country
      # Returns a Craigslist uri given the city subdomain
      #
      # @param city_path [String]
      # @return [String]
      def build_city_uri(city_path)
        case @@country
        when "canada"
          "http://#{city_path}.en.craigslist.ca"
        else
          "http://#{city_path}.craigslist.org"
        end
      end

      # Returns a Craigslist uri given city path, category path, options
      # including search, and offset
      #
      # @param city_path [String]
      # @param category_path [String]
      # @param options [Hash]
      # @param offset [Integer]
      # @return [String]
      def build_uri(city_path, category_path, options, offset=nil)

        # Vary url if any of the search options are not set
        if options[:query].nil? && options[:min_ask].nil? &&
           options[:max_ask].nil? && options[:has_image] == 0

          # Use the non-search uri
          uri = "#{build_city_uri(city_path)}/#{category_path}/"

          if offset && offset > 0
            uri = uri + "index#{offset}.html"
          end

          uri
        else
          # Use the search uri

          # Remove options with nil values
          options.reject! {|k, v| v.nil? }

          # Remove has_image if 0
          options.delete(:has_image) if options[:has_image] == 0

          # Replace the options keys with the keys from the map
          params = Hash[options.map {|k, v| [OPTIONS_PARAMS_MAP[k], v] }]

          # Prepend offset to params if not first page
          if offset && offset > 0
            params = Hash[s: offset].merge(params)
          end
          
          # Yuan: not used
          # query_string = build_query(params)
          query = params[:query]
          query.gsub!('(','%28')
          query.gsub!(')','%29')
          query.gsub!('|','%7C')
          query.gsub!('"','%22')
          query.gsub!(' ','+')
          
          # Yuan: fix query
          uri = "#{build_city_uri(city_path)}/search/#{category_path}?catAbb=#{category_path}&query=#{query}&zoomToPosting=&minAsk=&maxAsk=&sort=date"
          uri
        end
      end

      private

      # @param params [Hash]
      # @return [String]
      def build_query(params)
        params.map { |k, v|
          if v.class == Array
            build_query(v.map { |x| [k, x] })
          else
            v.nil? ? escape(k) : "#{escape(k)}=#{escape(v)}"
          end
        }.join('&')
      end

      # @param s [String]
      # @return [String]
      def escape(s)
        URI.encode_www_form_component(s)
      end
    end
  end
end
