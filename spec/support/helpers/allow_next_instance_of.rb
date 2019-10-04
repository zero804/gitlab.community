# frozen_string_literal: true

module AllowNextInstanceOf
  def allow_next_instance_of(klass, *new_args)
    receive_new = receive(:new)
    receive_new.with(*new_args) if new_args.any?

    allow(klass).to receive_new
      .and_wrap_original do |method, *original_args|
        method.call(*original_args).tap do |instance|
          yield(instance)
        end
      end
  end
end
