require 'core/system/library/cyclicmap'
require 'core/diff/code/equals'
require 'core/diff/code/diff'
require 'core/schema/tools/copy'

module Merge
  class Identify < MemoBase
    def self.placeholder_char
      "_"
    end
    
    def initialize(mapping, source, target, renaming = {})
      super()
      @mapping = mapping
      @source_root = source
      @target_root = target
      @mapping[source] = target 
      @renaming = renaming
    end

    def identify(obj)
      return if obj.nil? || @memo[obj]
      @memo[obj] = true
      obj.schema_class.fields.each do |f|
        Field(f, obj)
      end
    end

    def Field(field, obj)
      #puts "Visiting #{field} & #{obj}"
      return if field.computed
      if field.type.Primitive?
        if field.key
          name = obj[field.name]
          if @renaming[name] then
            analog = lookup_object(obj, @renaming[name])
            @mapping[obj] = analog
            #puts "MAP #{obj} to #{analog}"
          end
        end
      else
        if !field.many
          x = obj[field.name]
          identify(x)
        else
          obj[field.name].each do |x|
            identify(x)
          end
        end
      end  
    end

    # find an object with an equivalent name  
    def lookup_object(obj, name)
      # this scans the source during the recursive calls, 
      # then follows the same path in the target on the way out
      raise "Keys cannot be null" if obj.nil?
      #puts "Looking up #{obj}"
      rel_key_field = SchemaSchema.keyRel(obj.schema_class)
      if rel_key_field.nil?
        raise "Keys should connect to root but stop at #{obj}" if obj != @source_root
        return @target_root
      else
        key_field = SchemaSchema.key(obj.schema_class)

        raise "Key relationship fields must have inverses" if rel_key_field.inverse.nil?
        raise "A relationship key must have a data key as well" if key_field.nil?

        base = lookup_object(obj[rel_key_field.name], name)
        key = obj[key_field.name] #[1..-1]
        #puts "IDENTIFY #{key_field.name}/#{rel_key_field.name} key #{key}"
        return base[rel_key_field.inverse.name][name]
      end
    end
  end

  class Merge < Diff::Base
    def initialize()
      super()
    end

    def merge(from, to, factory, renaming = {})
      # adds identifications to the memo table
      @identity = {}

      @renaming = renaming

      @copier = Copy.new(factory, @identity)
      to = @copier.copy(to)

      id = Identify.new(@identity, from, to, renaming)
      id.identify(from)
      #p @identity

      
      diff(from, to)
      #p @diffs
      to.finalize
      to
    end

    # just insert everything from the left
    def ordered(field, o1, o2) 
      o1[field.name].each do |left|
        different_insert(o2, field, left)
      end
    end

    def keyed(field, o1, o2)
      #puts "KEY #{field} #{o1[field.name]} #{o2[field.name]}"
      o1[field.name].keys.each do |key_val|
        left = o1[field.name][key_val]
        #puts "KEYVAL #{key_val}"
        if @renaming[key_val] then
          #puts "It's in renaming"
          right = o2[field.name][@renaming[key_val]]
          raise "could not find object named #{key_val}" if right.nil?
          Type(field.type, left, right)
        else
          right = o2[field.name][key_val]
          #puts "RIGHT: #{field.name}, o1: #{o1}, o2: #{o2}, #{right}"
          raise "attempt to overwrite object named #{key_val}" unless right.nil?
          different_insert(o2, field, left)
        end
      end
    end

    def different_single(target, field, old, new)
      return if new.nil?
      if field.type.Primitive?
        return if field.key && new[0] == Identify.placeholder_char
        target[field.name] = new
        #puts "SET #{target}.#{field.name} = #{new}"
      else
        raise "Merge cannot change single-valued field #{target}.#{field.name} from #{old} to #{new}"
      end
    end

    def different_insert(target, field, new)
      #puts "COPYING #{target[field.name]}.#{field.name} #{new}"
      target[field.name] << @copier.copy(new)
    end
    
    def different_delete(target, field, old)
      raise "Merge cannot delete from #{target}.#{field.name}"
    end
  end
end

def merge(x, y, ren = {})
  Merge::Merge.new.merge(x, y, y._graph_id, ren)
end
  