require 'elasticsearch'
require 'log4r'

module Slaw
  # Support for indexing and search using elasticsearch
  class ElasticSearchSupport
    attr_accessor :es, :mapping, :index, :type, :base_url

    def initialize(index, type, base_url, client_params={}, es=nil)
      @es = es || create_client(client_params)

      @ix = index
      @type = type
      @base_url = base_url

      @mapping = {
        frbr_uri: {type: 'string', index: 'not_analyzed'},
        url: {type: 'string', index: 'not_analyzed'},
        title: {type: 'string', analyzer: 'english'},
        content: {type: 'string', analyzer: 'english'},
        published_on: {type: 'date', format: 'dateOptionalTime'},
        region: {type: 'string', index: 'not_analyzed'},
        region_name: {type: 'string', index: 'not_analyzed'},
        repealed: {type: 'boolean'},
      }

      @log = Log4r::Logger['Slaw']
    end

    def create_client(client_params)
      Elasticsearch::Client.new(client_params)
    end

    def reindex!(docs, &block)
      define_mapping!
      index_documents!(docs, &block)
    end

    def index_documents!(docs, &block)
      for doc in docs
        id = doc.id_uri.gsub('/', '-')

        data = {
          frbr_uri: doc.id_uri,
          url: @base_url + doc.id_uri,
          title: doc.short_title,
          content: doc.body.text,
          region: doc.region,
          published_on: doc.publication['date'],
          repealed: doc.repealed?,
        }

        yield doc, data if block_given?

        @log.info("Indexing #{id}")
        @es.index(index: @ix, type: @type, id: id, body: data)
      end
    end

    def define_mapping!
      @log.info("Deleting index")
      @es.indices.create(index: @ix) unless @es.indices.exists(index: @ix)

      # delete existing mapping
      unless @es.indices.get_mapping(index: @ix, type: @type).empty?
        @es.indices.delete_mapping(index: @ix, type: @type) 
      end

      @log.info("Defining mappings")
      @es.indices.put_mapping(index: @ix, type: @type, body: {
        @type => {properties: @mapping}
      })
    end

    def search(q, from=0, size=10)
      @es.search(index: @ix, body: {
        query: {
          multi_match: {
            query: q,
            type: 'cross_fields',
            fields: ['title', 'content'],
          }
        },
        fields: ['frbr_uri', 'repealed', 'published_on', 'title', 'url', 'region_name'],
        highlight: {
          order: "score",
          fields: {
            content: {
              fragment_size: 80,
              number_of_fragments: 2,
            },
            title: {
              number_of_fragments: 0, # entire field
            }
          },
          pre_tags: ['<mark>'],
          post_tags: ['</mark>'],
        },
        from: from,
        size: size,
        sort: {
          '_score' => {order: 'desc'}
        }
      })
    end
  end
end
