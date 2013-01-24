require 'java'
require 'core/diagram/code/swt'

require 'core/system/load/load'
require 'core/diagram/code/constraints'
#require 'core/schema/tools/print'

  # a path is specified by a constraint system
  #   the end is connected to a position on the part (h,w) 
  #       where (h==0 || h==1) || (w==0 || w==1)
  #   the path depends on the orientation. There are three cases:
  #     opp:   a--+
  #               |
  #               +--b
  #       
  #                 var:    a--+
  #                            |
  #                      +-----+
  #                      |
  #                      +--b
  #
  #                 var: +----------+
  #                      |          |
  #                      +--a    b--+
  #
  #     orth:  a--+    if a.P + a.PW + a.minP <= b.P + attach.P
  #               |
  #               b
  #       
  #                 var:    a--+     
  #                            |
  #                      +-----+
  #                      |
  #                      b
  #
  #                 var: +------+    
  #                      |      |
  #                      b   a--+
  #
  #     same:  a--+
  #               |
  #            b--+
  #       
  #                 var: b--+   a--+
  #                         |      |
  #                         +------+
  #
  #  but these can be in any orientation.
  #  Within each case there are some subcases

  def between(a, b, c)
    return (a - @DIST <= b && b <= c + @DIST) || (c - @DIST <= b && b <= a + @DIST)
  end
  
  def rect_contains(rect, pnt)
    rect.x <= pnt.x && pnt.x <= rect.x + rect.w \
    && rect.y <= pnt.y && pnt.y <= rect.y + rect.h
  end

  # compute distance of pnt from line
  def dist_line(p0, p1, p2)
    num = (p2.x - p1.x) * (p1.y - p0.y) - (p1.x - p0.x) * (p2.y - p1.y)
    den = (p2.x - p1.x) ** 2 + (p2.y - p1.y) ** 2
    return num.abs / Math.sqrt(den)
  end
  
def RunDiagramApp(content = nil)

  GUI::Application.run do 
    win = DiagramFrame.new
    win.set_root content if content
    win.show 
  end
end


class DiagramFrame < GUI::Window
  def initialize(title = 'Diagram')
    super(title)
    @selection = nil
    @mouse_down = false
    @select_color = GUI::Color.new(0, 255, 0)
    @DIST = 4
    @factory = ManagedData.new(Load('diagram.schema'))
  end
  
  attr_accessor :listener
  attr_accessor :foreground
  attr_accessor :font
  attr_accessor :factory
  
  def openFile
    dialog = FileDialog.new(self, "Choose a file", "", "", "Diagrams (*.diagram;)|*.diagram;")
    if dialog.show_modal() == ID_OK
      path = dialog.get_path
      extension = File.extname(path)
      raise "File is not a diagram" if extension != "diagram"
      content = Load(dialog.get_path())
      set_root(content)
    end
  end
  
  def set_root(root)
    #puts "ROOT #{root.class}"
    root.finalize
    #Print.print(root)
    @root = root
    clear_redraw
  end

  def clear_redraw
    redraw
    @cs = ConstraintSystem.new
    @positions = {}
  end      
  
  # ------- event handling -------  

  def mouse_down(e)
    #puts "DOWN #{e.x} #{e.y}"
    @mouse_down = true
    if @selection
      subselect = @selection.mouse_down(e)
      if subselect == :cancel
        @selection = nil
        return
      end
      if subselect
        @selection = subselect
        return
      end
    end
    select = find e do |x|
      #find something contained in a graph, which is dragable
      val = @find_container && @find_container.Container? && @find_container.direction == 3 
      #puts "#{x} => #{val}"
      val
    end
    #puts "FIND #{select}"
    set_selection(select, e)
  end
  
  def mouse_up(e)
    @mouse_down = false
  end

  def mouse_move(e)
    @selection.mouse_move(e, @mouse_down) if @selection
  end

  def key_pressed(e)
  
  end

  # ------- selections -------      
  def clear_selection
   if @selection
	    @selection = @selection.clear
	  end
  end
    
  def set_selection(select, e)
    clear_selection
    if select
      if select.Connector?
        @selection = ConnectorSelection.new(self, select)
      else
        @selection = MoveShapeSelection.new(self, select, EnsoPoint.new(e.x, e.y))
      end
    end
    redraw
  end
  
  # ---- finding ------
  def find(pnt, &filter)
    find1(@root, pnt, &filter)
  end
  
  def find1(part, pnt, &filter)
    if part.Connector?
      return findConnector(part, pnt, &filter)
    else
      b = boundary(part)
      return if b.nil?
      #puts "FIND #{part}: #{b.x} #{b.y} #{b.w} #{b.h}"
      begin
        if rect_contains(b, pnt)
          old_container = @find_container
          @find_container = part
          out = nil
          if part.Container?
            part.items.each do |sub|
              out = find1(sub, pnt, &filter)
              break if out
            end
            out = part if !out && filter.call(part)
          elsif part.Shape?
            out = find1(part.content, pnt, &filter) if part.content
          end
          @find_container = old_container
          return out if out
          return part if filter.call(part)
        end
      rescue Exception => e  
        puts e.message
      end
    end
    return nil
  end
  	
  def findConnector(part, pnt, &filter)
    part.ends.each do |e|
      if e.label
        obj = find1(e.label, pnt, &filter)
        return obj if obj
        obj = find1(e.other_label, pnt, &filter)
        return obj if obj
      end
    end
    from = nil
    #puts "FindCon #{part.path.length}"
    part.path.each do |to|
      if !from.nil?
	      #puts "  LINE (#{from.x},#{from.y}) (#{to.x},#{to.y}) with (#{pnt.x},#{pnt.y})"
	      if between(from.x, pnt.x, to.x) && between(from.y, pnt.y, to.y) && dist_line(pnt, from, to) <= @DIST
	        return part
	      end
	    end
			from = to
    end
    return nil
  end

  # ----- constrain -----
  def get_var(name, constraint)
    if constraint && constraint.var
      var = @cs[constraint.var]
    else
      var = @cs.var(name)
    end    
    var >= constraint.min if constraint && constraint.min
    return var
  end
  
  def do_constraints
    constrain(@root, @cs.value(0), @cs.value(0)) 
  end
  
  def constrain(part, x, y)
    puts "CONST #{part} #{x} #{y}"
    w, h = nil
    with_styles part do 
      if part.Connector?
        send(("constrain" + part.schema_class.name).to_sym, part)
      else
        w = get_var("#{part}_w", part.constraints && part.constraints.width)
        h = get_var("#{part}_h", part.constraints && part.constraints.height)
    
        send(("constrain" + part.schema_class.name).to_sym, part, x, y, w, h)
        @positions[part] = EnsoRect.new(x, y, w, h)
      end
    end
    return w, h
  end

  def constrainContainer(part, basex, basey, width, height)
    pos = @cs.value(0)
    otherpos = @cs.value(0)
    x, y = basex + 0, basey + 0
    #puts "CONTAINER #{width.to_s}, #{height.to_s}"
    part.items.each_with_index do |item, i|
      w, h = constrain(item, x, y)
      next if w.nil?
      #puts "ITEM #{i}/#{part.items.length}"
      case part.direction
      when 1 then #vertical
        pos = pos + h
        y = basey + pos
        width >= w
      when 2 then #horizontal
        pos = pos + w
        x = basex + pos
        height >= h
      when 3 then #graph
        # compute the default positions!!
        pos = pos + w
        otherpos = otherpos + h
        x = basex + pos
        y = basey + otherpos
        width >= x + w
        height >= y + h
      end
    end
    case part.direction
    when 1 then #vertical
      height >= pos
    when 2 then #horizontal
      width >= pos
    end
  end  
  
  def constrainShape(part, x, y, width, height)
    case part.kind 
    when "oval"
      a = @cs.var("pos1", 0)
      b = @cs.var("pos2", 0)
    when "rounded"
      a = b = 20
    else
      a = b = 0
    end
    margin = @graphics.stroke_width
    puts "CO #{@graphics.stroke_color}"
    puts "AB #{part.kind}, #{a}, #{b}, #{margin}"
    a, b = a + margin, b + margin
    ow, oh = constrain(part.content, x + a, y + b)
    # position of sub-object depends on size of sub-object, so we
    # have to be careful about the circular dependencies
    if part.kind == "oval"
      sq2 = 2 * Math.sqrt(2.0)
      a >= (ow / sq2).round
      b >= (oh / sq2).round
      a >= b
    end
    width >= ow + (a * 2)
    height >= oh + (b * 2)
  end

  def constrainText(part, x, y, width, height)
    w, h = @graphics.get_text_extent(part.string)
    width >= w
    height >= h
  end

  def constrainConnector(part)
    part.ends.each do |ce|
      to = @positions[ce.to]
      x = ( to.x + to.w * ce.attach.dynamic_update.x ).round
      y = ( to.y + to.h * ce.attach.dynamic_update.y ).round
      @positions[ce] = EnsoPoint.new(x, y)
      constrainConnectorEnd(ce, x, y)
    end
  end
  
  def constrainConnectorEnd(e, x, y)
    constrain(e.label, x, y) if e.label
    constrain(e.other_label, x, y) if e.other_label
  end
  
  def boundary(shape)
    r = @positions[shape]
    return nil if r.nil?
    return EnsoRect.new(r.x.value, r.y.value, r.w.value, r.h.value)
  end

  def position(shape)
    p = @positions[shape]
    return nil if p.nil?
    return EnsoPoint.new(p.x.value, p.y.value)
  end
  
  def set_position(shape, x, y)
    @positions[shape].x.value = x
    @positions[shape].y.value = y
  end
  
  
  # ----- drawing --------    
  # Writes the gruff graph to a file then reads it back to draw it
  def on_paint(graphics, rect, count)
    @graphics = graphics
    do_constraints() if @positions == {}
    draw(@root)
    @selection.paint(@graphics) if @selection
  end
  
  def draw(part)
    with_styles part do 
      send(("draw" + part.schema_class.name).to_sym, part)
    end
  end

  def drawContainer(part)
    if part.direction == 3
	    r = boundary(part)
	    @graphics.draw_rectangle(r.x, r.y, r.w, r.h)
	  end
    (part.items.length-1).downto(0).each do |i|
      draw(part.items[i])
    end
  end  
  
  def drawShape(shape)
    r = boundary(shape)
    margin = @graphics.stroke_width
    m2 = margin - (margin % 2)
    case shape.kind
    when "box"
      @graphics.draw_rectangle(r.x + margin / 2, r.y + margin / 2, r.w - m2, r.h - m2)
    when "oval"
	    @graphics.draw_ellipse(r.x + margin / 2, r.y + margin / 2, r.w - m2, r.h - m2)
	  end
    draw(shape.content)
  end
  
  def drawConnector(part)
    e0 = part.ends[0]
    e1 = part.ends[1]
    pFrom = position(e0)
    pTo = position(e1)

    # compute what side of the shapes both ends are on
    sideFrom = getSide(e0.attach)
    sideTo = getSide(e1.attach)
    if sideFrom == sideTo   # this it the "same" case
      ps = simpleSameSide(pFrom, pTo, sideFrom)
    elsif (sideFrom - sideTo).abs % 2 == 0  # this is the "opposite" case
      ps = simpleOppositeSide(pFrom, pTo, sideFrom)
    else  # this is the "orthogonal" case
      ps = simpleOrthogonalSide(pFrom, pTo, sideFrom)
    end

    ps.unshift(pFrom)
    ps << pTo

    part.path.clear
    ps.each {|p| part.path << @factory.Point(p.x, p.y) }
#    @graphics.draw_lines(ps.collect {|p| [p.x, p.y] })
    @graphics.draw_spline(ps.collect {|p| [p.x, p.y] })

    drawEnd part.ends[0]
    drawEnd part.ends[1]
  end

  def drawEnd(cend)
    side = getSide(cend.attach)

    # draw the labels
    r = boundary(cend.label) || boundary(cend.other_label)
    if r
	    case side
	    when 0 # UP
	      angle = 90
	      offset = EnsoPoint.new(-r.h, 0)
	    when 1 #RIGHT
	    	angle = 0
	      offset = EnsoPoint.new(0, -r.h)
	    when 2 # DOWN
	      angle = -90
	      offset = EnsoPoint.new(r.h, 0)
	    when 3 # LEFT
	    	angle = 0
	      r.y = r.y - r.h
	      r.x = r.x - r.w
	      offset = EnsoPoint.new(0, r.h)
	    end
	    with_styles cend.label do 
		    @graphics.draw_rotated_text(cend.label.string, r.x, r.y, angle)
		  end
	    with_styles cend.other_label do 
		    @graphics.draw_rotated_text(cend.other_label.string, r.x + offset.x, r.y + offset.y, angle)
		  end
		end

    # draw the arrows
    if cend.arrow == ">" || cend.arrow == "<"
      size = 5
      angle = -Math::PI * (1 - side) / 2
      arrow = [ EnsoPoint.new(0,0), EnsoPoint.new(2,1), EnsoPoint.new(2,-1), EnsoPoint.new(0,0) ].collect do |p|
	      px = Math.cos(angle) * p.x - Math.sin(angle) * p.y
				py = Math.sin(angle) * p.x + Math.cos(angle) * p.y
				[ (px * size).round, (py * size).round ]
		  end
		  #puts "ARROW #{arrow}"
      pos = position(cend)
      @graphics.draw_polygon(arrow, pos.x, pos.y)
    end
  end

  # draw 
  def simpleSameSide(a, b, d)
    case d
    when 2 # DOWN
      z = [a.y + 10, b.y + 10].max
      return [EnsoPoint.new(a.x, z), EnsoPoint.new(b.x, z)]
    when 0 # UP
      z = [a.y - 10, b.y - 10].min
      return [EnsoPoint.new(a.x, z), EnsoPoint.new(b.x, z)]
    when 1 # RIGHT
      z = [a.x + 10, b.x + 10].max
      return [EnsoPoint.new(z, a.y), EnsoPoint.new(z, b.y)]
    when 3 # LEFT
      z = [a.x - 10, b.x - 10].min
      return [EnsoPoint.new(z, a.y), EnsoPoint.new(z, b.y)]
    end  
  end

  # connector is from top to bottom or left to right
  def simpleOppositeSide(a, b, d)
    case d
    when 0, 2 # UP, DOWN
      z = average(a.y, b.y)
      return [EnsoPoint.new(a.x, z), EnsoPoint.new(b.x, z)]
    when 1, 3# LEFT, RIGHT
      z = average(a.x, b.x)
      return [EnsoPoint.new(z, a.y), EnsoPoint.new(z, b.y)]
    end
  end

  def average(m, n)
    return Integer((m + n) / 2)
  end

  # need to handle more cases
  def simpleOrthogonalSide(a, b, d)
    case d
    when 0, 2 # 
      return [EnsoPoint.new(a.x, b.y)]
    when 1, 3 # LEFT, RIGHT
      return [EnsoPoint.new(b.x, a.y)]
    end  
  end

  # compute the side of an attachment point for a connector end
  # sides are labeld top=0, right=1, bottom=2, left=3  
  def getSide(cend)
    return 0 if cend.y == 0 #top
    return 1 if cend.x == 1 #right
    return 2 if cend.y == 1 #bottom
    return 3 if cend.x == 0 #left
  end

  def drawText(text)
    r = boundary(text)
    @graphics.draw_text(text.string, r.x, r.y)
  end
 
  #  --- helper functions ---
  def with_styles(part)
    return if part.nil?
    @graphics.push_style(part.style) do
      if @selection && @selection.is_selected(part)
        @graphics.stroke_color = @select_color
      end
      yield
    end
  end

  def makeColor(c)
    return GUI::Color.new(to_byte(c.r), to_byte(c.g), to_byte(c.b))
  end
  
  def to_byte(v)
    return [0, [255, v.to_i].min].max
  end
end

############# selection #####

class MoveShapeSelection
	def initialize(diagram, part, down)
	  @diagram = diagram
	  @part = part
    @down = down
    @move_base = @diagram.boundary(part)
  end
  
  def mouse_move(e, down)
    if down
      @diagram.set_position(@part, @move_base.x + (e.x - @down.x), @move_base.y + (e.y - @down.y))
      @diagram.redraw
    end
  end
  
  def is_selected(check)
    return @part == check
  end
  
  def paint(graphics)
  end

  def mouse_down(e)
	end
	 
  def clear
  end
end

class ConnectorSelection
	def initialize(diagram, conn)
	  @diagram = diagram
	  @conn = conn
  end
  
  def is_selected(check)
    return @conn == check
  end

  def paint(graphics)
	  size = 8
	  p = @conn.path[0]
    graphics.draw_rectangle(p.x - size / 2, p.y - size / 2, size, size)
	  p = @conn.path[-1]
    graphics.draw_rectangle(p.x - size / 2, p.y - size / 2, size, size)
#    @conn.path.each do |p|
#	  end
  end
    
  def mouse_down(e)
	  size = 8
	  pnt = @diagram.factory.Point(e.x, e.y)
	  p = @conn.path[0]
    r = @diagram.factory.Rect(p.x - size / 2, p.y - size / 2, size, size)
    if rect_contains(r, pnt)
      return PointSelection.new(@diagram, @conn.ends[0], self, p)
    end

	  p = @conn.path[-1]
    r = @diagram.factory.Rect(p.x - size / 2, p.y - size / 2, size, size)
    if rect_contains(r, pnt)
      return PointSelection.new(@diagram, @conn.ends[1], self, p)
    end
  end

  def mouse_move(e, down)    
  end
  
  def clear
  end
end

class PointSelection
	def initialize(diagram, ce, selection, pnt)
	  @diagram = diagram
	  @ce = ce
	  @selection = selection
	  @pnt = pnt
  end
  
  def is_selected(check)
    return @ce == check
  end

  def paint(graphics)
	  size = 8
    graphics.draw_rectangle(@pnt.x - size / 2, @pnt.y - size / 2, size, size)
  end
    
  def mouse_down(e)
  end

  def mouse_move(e, down)
    return if !down
    pos = @diagram.boundary(@ce.to)
    x = (e.x - (pos.x + pos.w / 2)) / Float(pos.w / 2)
    y = (e.y - (pos.y + pos.h / 2)) / Float(pos.h / 2)
    return if x == 0 && y == 0
    #puts("FROM #{x} #{y}")
    angle = Math.atan2(y, x)
    nx = normalize(Math.cos(angle))
    ny = normalize(Math.sin(angle))
    #puts("   EDGE #{nx} #{ny}")
		@ce.attach.x = nx
		@ce.attach.y = ny
    @diagram.redraw
    #puts("   EDGE #{@ce.attach.x} #{@ce.attach.y}")
  end
  
  def normalize(n)
    n = n * Math.sqrt(2)
    n = [-1, n].max
    n = [1, n].min
    n = (n + 1) / 2
    return n
  end
  
  def clear
    return @selection
  end
end

	
############# low level geometry #####

class EnsoPoint
  def initialize(x, y)
    @x = x
    @y = y
  end
  attr_accessor :x, :y
end

class EnsoRect
  def initialize(x, y, w, h)
    @x = x
    @y = y
    @w = w
    @h = h
  end
  attr_accessor :x, :y, :w, :h  
end

	