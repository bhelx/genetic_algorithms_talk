# utilities

# random floored number b/w 0 and n
randFloor = (n) ->
  rand = Math.random()
  rand *= n if n
  Math.floor(rand)

# from ascii code to character
chr = String.fromCharCode
# from character to ascii code
ord = (character) -> character.charCodeAt(0)

# like python zip
zip = () ->
  lengthArray = (arr.length for arr in arguments)
  length = Math.min(lengthArray...)
  for i in [0...length]
    arr[i] for arr in arguments

# classes

class Gene
  constructor: (@code) ->
    @fitness = Number.MAX_VALUE

  randomize: (length) ->
    @code = [1..length].map(-> chr(randFloor(128))).join('')

  mutate: (chance) ->
    return if Math.random() > chance

    index = randFloor(@code.length)
    direction = if Math.random() < 0.5 then -1 else 1
    newChar = chr(@code.charCodeAt(index) + direction)

    # replace the character at `index` with `newChar`
    @code = @code.substr(0,index) + newChar + @code.substr(index+1)

  mate: (otherGene) ->
    pivot = Math.round(@code.length / 2) - 1

    child1 = @code[0..pivot] + otherGene.code[pivot+1..-1]
    child2 = otherGene.code[0..pivot] + @code[pivot+1..-1]

    [new Gene(child1), new Gene(child2)]

  calculateFitness: (goal) ->
    zipped = zip(@code.split(''), goal.split(''))
    fitnesss = zipped.map((pair) -> Math.pow(ord(pair[0]) - ord(pair[1]), 2))
    @fitness = fitnesss.reduce (x, y) -> x + y


class Population
  constructor: (@goal, @size, @mutationRate) ->
    @generationNumber = 0
    @members = [1..size].map () =>
      gene = new Gene()
      gene.randomize(@goal.length)
      gene

  sort: () ->
    @members.sort (a, b) -> a.fitness - b.fitness

  generation: () ->
    @members.forEach (member) => member.calculateFitness(@goal)
    @sort()

    if @members[0].fitness == 0 #winner
      @onEvolved()
      return

    children = @members[0].mate(@members[1])
    @members = @members[0..-3]          # pop off last two, most inferior
    @members = @members.concat children # add the genetically superior children

    @members.forEach (member) =>
      member.mutate(@mutationRate)
      member.calculateFitness(@goal)

    @generationNumber++

class App
  constructor: () ->
    # range listeners
    $("[name=range-evolution]").on "change", () ->
      $("[for=range-evolution]").val("#{this.value} ms")
    .trigger("change")
    $("[name=range-mutation]").on "change", () ->
      $("[for=range-mutation]").val("#{Math.floor(this.value * 100)} %")
    .trigger("change")
    $("[name=range-population]").on "change", () ->
      $("[for=range-population]").val(this.value)
    .trigger("change")

  stopEvolution: () ->
    clearInterval @interval

  startEvolution: () ->
    populationSize = $('[name=range-population]').val()
    mutationRate = $('[name=range-mutation]').val()
    speed = $('[name=range-evolution]').val()
    goal = $('[name=goal]').val() || 'Hello World!'

    @population = new Population(goal, populationSize, mutationRate)

    # set the callback from when evolution is done
    @population.onEvolved = () =>
      clearInterval(@interval)
      @render()

    @interval = setInterval () =>
      @population.generation()
      @render()
    , speed

  render: () ->
    document.getElementById('generation').innerText = @population.generationNumber
    document.getElementById('fittest').innerText = @population.members[0].code
    document.getElementById('fitness').innerText = @population.members[0].fitness
    table = $('.population')
    table.empty()

    buildRow = (row) ->
      row.reduce (memo, member) ->
        memo += "<td>#{member.code} (<b>#{member.fitness}</b>)</td>"
      , ''

    tableHtml = ''
    numCols = 10
    for i in [0...@population.members.length] by numCols
      row = @population.members[i...i+numCols]
      tableHtml += "<tr>#{buildRow(row)}</tr>"

    table.append(tableHtml)

$(document).ready () ->

  app = new App
  app.startEvolution()

  $('.reload').click (event) ->
    event.preventDefault()
    app.stopEvolution()
    app.startEvolution()

