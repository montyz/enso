require 'core/semantics/code/interpreter'
require 'core/expr/code/lvalue'
require 'core/expr/code/env'

module ExecuteController
  include LValueExpr

  def init_Controller(globals, args=nil)
    globals.each {|g| execute(g, args)}
  end

  def execute_Controller(current, args=nil)
    execute(current, args)
  end

  def execute_State(commands, transitions, args=nil)
    #test conditions BEFORE executing current state!!!
    moved = transitions.detect do |trans|
      execute(trans, args)
    end
    if !moved
      commands.each do |c|
        execute(c, args)
      end
    end
  end

  def execute_Transition(guard, target, args=nil)
    if self.eval(guard, args)
      args[:control].current = target
      true
    else
      false
    end
  end

  def execute_Assign(var, val, args=nil)
    lvalue(var, args).value = self.eval(val, args)
  end

  def execute_TurnSplitter(splitter, percent, args=nil)
    args[:env][splitter].position = [[percent, 1.0].min, 0.0].max
  end
end

class Controller

  def initialize(piping, control)
    #piping is the interface to the state of the pipes. connects either to a simulator or hardware
    #state is the current state of the controller, used to store global runtime variables
    @piping = piping
    @control = control
    @env = ControlEnv.new(@piping).set_parent({})
    @interp = Interpreter(ExecuteController)
    @interp.init(@control, :env=>@env)
  end

  class ControlEnv
    include Env
    def initialize(piping)
      @piping = piping
    end
    def [](key)
      if @piping.sensor_names.include? key
        @piping.get_sensor(key)
      elsif @piping.control_names.include? key
        @piping.get_control(key)
      else
        @parent.nil? ? nil : @parent[key]
      end
    end
    def []=(key, value)
      if @piping.control_names.include? key
        @piping.set_control_value(key, value)
      else
        @parent[key] = value
      end
    end
    def each(&block)
      @piping.sensor_names.each do |sn|
        yield sn, @piping.get_sensor(sn)
      end
      @piping.control_names.each do |cn|
        yield cn, @piping.get_control(cn)
      end
      @parent.each &block unless @parent.nil?
    end
  end

  def run
    @interp.execute(@control, :env=>@env, :piping=>@piping, :control=>@control)
  end
end
