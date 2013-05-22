require 'matrix'
require 'ruby-sdl-ffi/sdl'
require 'ruby-sdl-ffi/gfx'

class Particle
  attr_accessor:position, :velocity, :acceleration 
  attr_accessor:age, :life, :color, :size
  def initialize(pos, vel, life, color, size)
    @acceleration, @age = Vector[0, 0], 0
    @position, @velocity, @life, @color, @size = pos, vel ,life, color, size
  end
end

class ParticleSystem
  attr_accessor:particles
  attr_accessor:gravity
  attr_accessor:effectors

  def initialize
    @particles = []  
    @gravity   = Vector[0, 100]
    @effectors = []
  end

  def emit(particle)
    @particles << particle
  end

  def simulate(dt)
    _aging dt 
    _apply_gravity dt
    _apply_effectors
    _kinematics dt
  end

  def render(screen)
    @particles.each do |e|
      alpha = (1 - e.age / e.life) * 255
      SDL::Gfx.filledCircleRGBA screen, e.position[0], e.position[1], e.size,
                                e.color[0], e.color[1] , e.color[2], alpha 
  
    end    
  end
private
  def _aging(dt)
    @particles.each {|e| e.age += dt } 
    @particles.delete_if {|e| e.age >= e.life }
  end

  def _apply_gravity(dt)
    @particles.each {|e| e.acceleration = @gravity }
  end
  
  def _apply_effectors
    @effectors.each do |effector|
      @particles.each {|e| effector.apply e }
    end    
  end

  def _kinematics(dt)
    @particles.each do |e|
      e.position = e.position + e.velocity * dt
      e.velocity = e.velocity + e.acceleration * dt
    end
  end
end

class ChamberBox
  def initialize(x1, y1, x2, y2)
   @x1, @y1, @x2, @y2 = x1, y1, x2, y2 
  end

  def apply(particle)
    if particle.position[0] - particle.size < @x1 || 
       particle.position[0] + particle.size > @x2
      particle.velocity.send :[]=, 0, - particle.velocity[0]
    end 
     if particle.position[1] - particle.size < @y1 ||
        particle.position[1] + particle.size > @y2
       particle.velocity.send :[]=, 1,  -particle.velocity[1]
     end 
  end
end

def sample_direction(angle1, angle2)
  t = rand
  theta = angle1 * t + angle2 *(1 - t);
  Vector[Math.cos(theta), Math.sin(theta)]  
end

def sample_color(color1, color2)
  t = rand
  color1 * t + (color2 *(1 - t))  
end

def sample_number(value1, value2)
  t = rand
  value1 * t + (value2 *(1 - t))  
end

def step(screen, ps, dt)
  velocity = (@new_mouse_position - @old_mouse_position) * 10
  velocity += sample_direction(0, Math::PI * 2) * 20 
  color = sample_color(Vector[255, 0, 0], Vector[255, 255, 0])
  life  = sample_number 1, 3
  size  = sample_number 2, 4
  
  ps.emit Particle.new(@new_mouse_position, velocity, life, color, size) 
  @old_mouse_position = @new_mouse_position
  ps.simulate dt
  SDL::Gfx.boxRGBA screen, 0, 0, @width, @width,  0, 0, 0, 25
  ps.render screen
end

def demo_main
  @width, @height = 480, 320 
  @new_mouse_position = Vector[0, 0]
  @old_mouse_position = Vector[0, 0]

  ps = ParticleSystem.new 
  ps.effectors << ChamberBox.new(0, 0, @width, @height)
  dt = 0.01
  quit = false 

  SDL.Init(SDL::INIT_VIDEO)
  screen = SDL.SetVideoMode(@width, @height, 32, 0)
  while !quit 
    while event = SDL.PollEvent
      case event.type 
      when SDL::MOUSEMOTION
        @new_mouse_position = Vector[event.x, event.y] 
      when SDL::KEYUP
        quit = true if event.keysym.sym == SDL::K_ESCAPE
      when SDL::QUIT  
        quit = true 
      end
    end
    step screen, ps, dt
    return if SDL.Flip(screen) == -1
    SDL.Delay 1000/100 
  end
end

demo_main
