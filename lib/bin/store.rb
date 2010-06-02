# encoding: UTF-8
module Bin
  class Store < Compatibility
    attr_reader :collection, :options

    def initialize(collection, options={})
      @collection, @options = collection, options
    end

    def expires_in
      @expires_in ||= options[:expires_in] || 1.year
    end

    def write(key, value, options=nil)
      super do
        expires = Time.now.utc + ((options && options[:expires_in]) || expires_in)
        doc     = {:_id => key, :value => value, :expires_at => expires}
        collection.save(doc)
      end
    end

    def read(key, options=nil)
      super do
        if doc = collection.find_one(:_id => key, :expires_at => {'$gt' => Time.now.utc})
          doc['value']
        end
      end
    end

    def delete(key, options=nil)
      super do
        collection.remove(:_id => key)
      end
    end

    def delete_matched(matcher, options=nil)
      super do
        collection.remove(:_id => matcher)
      end
    end

    def exist?(key, options=nil)
      super do
        !read(key, options).nil?
      end
    end

    def increment(key, amount=1)
      super do
        counter_key_upsert(key, amount)
      end
    end

    def decrement(key, amount=1)
      super do
        counter_key_upsert(key, -amount.abs)
      end
    end

    def clear
      collection.remove
    end

    def stats
      collection.stats
    end

    private
      def counter_key_upsert(key, amount)
        collection.update(
          {:_id => key}, {
            '$inc' => {:value => amount},
            '$set' => {:expires_at => Time.now.utc + 1.year},
          }, :upsert => true)
      end
  end
end