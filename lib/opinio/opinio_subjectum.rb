module Opinio
  module OpinioSubjectum
  
    def self.included(base)
      base.extend(ClassMethods)
    end
  
    module ClassMethods
      def opinio_subjectum(*args)
        options = args.extract_options!
        options.delete(:as)

        default_options = { :class_name => Opinio.model_name,
                            :as => :commentable,
                            :dependent => :destroy }

        has_many :comments, -> { order "created_at #{Opinio.sort_order}" }, default_options.merge(options)
        
      end
    end
  
  end
end
