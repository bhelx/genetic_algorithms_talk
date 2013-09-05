
# main closure
sketchProc = (processing) ->

  PVector = processing.PVector

  class Target
    constructor: ->
      @size = 20
      @x = processing.width - @size + 1
      @y = (processing.height / 2.0) - (@size / 2.0)
      @width = @size
      @height = @size

    render: ->
      processing.rect(@x, @y, @size, @size)

  class Obstruction
    constructor: (@position, @width, @height) ->
      @x = Math.random() * processing.width
      @y = Math.random() * processing.height
      @width = Math.random() * 30 + 10
      @height = Math.random() * 30 + 60

    render: ->
      processing.rect(@x, @y, @width, @height)

  class Seeker
    constructor: (@gridSize, @field) ->
      @reset()

    reset: ->
      centerY = processing.height / 2
      @position = new PVector(5.0, centerY)
      @acceleration = new PVector(0.0, 0.0)
      @velocity = new PVector(1.0, 0.0)
      @size = 2
      @fitness = Number.MAX_VALUE
      @createFlowField() unless @field
      @dead = false
      @won = false

    randomFlow: ->
      new PVector((Math.random()*2.0 - 1.0) * 0.1, (Math.random()*2.0 - 1.0) * 0.1)

    createFlowField: () ->
      @field = [1..@gridSize].map =>
        [1..@gridSize].map =>
          @randomFlow()

    fieldForce: ->
      x = processing.constrain(Math.floor((@position.x / processing.width) * @gridSize), 0, @gridSize - 1)
      y = processing.constrain(Math.floor((@position.y / processing.height) * @gridSize), 0, @gridSize - 1)
      @field[x][y]

    mutate: ->
      x = Math.floor(Math.random() * @field.length)
      #y = Math.floor(Math.random() * @field.length)
      #@field[x][y] = @randomFlow()
      @field[x] = [1..@field.length].map => @randomFlow()

    calculateFitness: (target) ->
      dist = processing.dist(target.x, target.y, @position.x, @position.y)

      @fitness = 1000 * (1 / (dist + 0.001))
      @fitness = Math.pow(@fitness, 2) unless @dead
      @fitness = Math.pow(@fitness, 2) if @won

    detectWalls: ->
      x = @position.x > processing.width
      y = @position.y < 0 || @position.y > processing.height

      @dead = true if @position.x < 0
      @velocity.x *= -0.33 if x
      @velocity.y *= -0.33 if y

    detectCollision: (rect) ->
      x = @position.x > rect.x && @position.x < rect.x + rect.width
      y = @position.y > rect.y && @position.y < rect.y + rect.height

      if x && y
        @position = @lastPosition
        @dead = true
        true

    detectWin: (target) ->
      x = @position.x > target.x && @position.x < target.x + target.width
      y = @position.y > target.y && @position.y < target.y + target.height

      if x && y
        @won = true

    detectObstruction: (obstructions) ->
      obstructions.map (obstruction) =>
        @detectCollision(obstruction)

    friction: ->
      friction = @velocity.get()
      friction.mult(-1)
      friction.normalize()
      friction.mult(0.001)
      friction

    applyForces: ->
      @acceleration.mult(0) #clear out
      @acceleration.add(@fieldForce())
      #@acceleration.add(@friction())

    tick: (obstructions, target) ->
      return if @dead || @won

      @lastPosition = @position.get()
      @applyForces()
      @velocity.add(@acceleration)
      @position.add(@velocity)
      @detectWin(target)
      @detectObstruction(obstructions)
      @detectWalls()
      @calculateFitness(target)

    render: ->
      theta = @velocity.heading2D() + processing.radians(90)
      processing.pushMatrix()
      processing.translate(@position.x, @position.y)
      processing.rotate(theta)
      processing.beginShape(processing.TRIANGLES)
      processing.vertex(0, -@size * 2)
      processing.vertex(-@size, @size * 2)
      processing.vertex(@size, @size * 2)
      processing.endShape()
      processing.popMatrix()

  class Population
    constructor: ->
      @obstructions = [1..4].map ->
        new Obstruction()
      @target = new Target()
      @gridSize = 50
      @generations = 1
      @iterations = 1
      @timeout = 400
      @mutationRate = 0.1
      @size = 200
      @seekers = [1..@size].map => new Seeker(@gridSize)

    tick: ->
      @seekers.map (seeker) => seeker.tick(@obstructions, @target)
      @iterations++

    render: ->
      @target.render()
      @obstructions.map (obstruction) -> obstruction.render()
      @seekers.map (seeker) => seeker.render()

    evolve: ->
      @sort()

      #seeker.reset() for seeker in @seekers when seeker.dead

      # mate top 20, replace last 40
      for i in [0...20] by 2
        children = @mate(@seekers[i], @seekers[i+1])
        @seekers[@size-i-1] = children[0]
        @seekers[@size-i-2] = children[1]

      @mutate()
      @seekers.map (seeker) -> seeker.reset()
      @iterations = 1

    timedOut: ->
      @iterations > @timeout

    mate: (seeker, other_seeker) ->
      half = seeker.field.length / 2
      gridSize = seeker.gridSize
      field1 = seeker.field[0..half].slice().concat(other_seeker.field[half+1..-1])
      field2 = other_seeker.field[0..half].slice().concat(seeker.field[half+1..-1])

      [new Seeker(gridSize, field1), new Seeker(gridSize, field1)]

    mutate: ->
      seeker.mutate() for seeker in @seekers when Math.random() > @mutationRate

    sort: ->
      @seekers.sort (a, b) -> b.fitness - a.fitness

  processing.setup = =>
    processing.size(800, 500)
    processing.strokeWeight(1.0)
    processing.fill(255)
    @population = new Population()

  processing.draw = =>
    processing.background(224)
    if @population.timedOut()
      @population.evolve()
    else
      @population.tick()
      @population.render()

canvas = document.getElementById("canvas1")
processingInstance = new Processing(canvas, sketchProc)

