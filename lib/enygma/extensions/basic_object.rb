module Enygma
  if defined? BasicObject and RUBY_VERSION >= '1.9'
    Enygma::BasicObject = ::BasicObject
  else
    class BasicObject
      instance_methods.each { |m| undef_method m unless %w{ __id__ __send__ }.include?(m) }
    end
  end
end