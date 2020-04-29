
Rake::Application.class_eval do

  alias origin_top_level top_level

  def top_level
    @top_level_tasks = [top_level_tasks.join(' ')]
    origin_top_level
  end

  def parse_task_string(_)
    args = ARGV.clone
    return args.shift, args
  end

end

Rake::Task.class_eval do

  class DummyArguments < Array
    def new_scope(_)
      self
    end
  end

  def invoke(*args)
    wrapped_args = DummyArguments.new
    wrapped_args.concat args
    invoke_with_call_chain(wrapped_args, Rake::InvocationChain::EMPTY)
  end

end

