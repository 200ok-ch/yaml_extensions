require 'yaml'

require 'yaml_extensions/version'

class Hash
  def deep_merge!(other_hash, &block)
    merge!(other_hash) do |key, this, that|
      if this.is_a?(Hash) && that.is_a?(Hash)
        this.deep_merge!(that, &block)
      elsif block_given?
        yield(key, this, that)
      else
        that
      end
    end
  end

  def walk(&block)
    reduce({}) do |aggregator, entry|
      key, val = entry
      nval = val.class.method_defined?(:walk) ? val.walk(&block) : val
      aggregator.merge(key => nval)
    end.tap { |result| yield(result) if block_given? }
  end
end

class Array
  def walk(&block)
    map { |e| e.class.method_defined?(:walk) ? e.walk(&block) : e }
  end
end

module YamlExtensions
  def load(*args)
    super(*args).walk do |h|
      h.keys.sort.reverse_each do |key|
        if key =~ /^<<<\d*$/
          h.deep_merge!(h.delete(key)) { |_, this, _| this }
        end
      end
    end
  end
end

module YAML
  class << self
    prepend YamlExtensions
  end
end

puts YAML.dump(YAML.load(ARGF.read)) if $PROGRAM_NAME == __FILE__
