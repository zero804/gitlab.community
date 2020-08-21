# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authorize
      module AuthorizeResource
        extend ActiveSupport::Concern

        RESOURCE_ACCESS_ERROR = "The resource that you are attempting to access does not exist or you don't have permission to perform this action"

        class_methods do
          def required_permissions
            # If the `#authorize` call is used on multiple classes, we add the
            # permissions specified on a subclass, to the ones that were specified
            # on its superclass.
            @required_permissions ||= if self.respond_to?(:superclass) && superclass.respond_to?(:required_permissions)
                                        superclass.required_permissions.dup
                                      else
                                        []
                                      end
          end

          def authorize(*permissions)
            required_permissions.concat(permissions)
          end

          def authorizes_object?
            defined?(@authorizes_object) ? @authorizes_object : false
          end

          def authorizes_object!
            @authorizes_object = true
          end
        end

        def find_object(*args)
          raise NotImplementedError, "Implement #find_object in #{self.class.name}"
        end

        def authorized_find!(*args, **kwargs)
          object = Graphql::Lazy.force(find_object(*args, **kwargs))

          authorize!(object)

          object
        end

        # authorizes the object using the current class authorization.
        def authorize!(object)
          raise_resource_not_available_error! unless authorized_resource?(object)
        end

        def authorized_resource?(object)
          # Sanity check. We don't want to accidentally allow a developer to authorize
          # without first adding permissions to authorize against
          if self.class.authorization.none?
            raise Gitlab::Graphql::Errors::ArgumentError, "#{self.class.name} has no authorizations"
          end

          self.class.authorization.ok?(object, current_user)
        end

        def raise_resource_not_available_error!(msg = RESOURCE_ACCESS_ERROR)
          raise Gitlab::Graphql::Errors::ResourceNotAvailable, msg
        end
      end
    end
  end
end
