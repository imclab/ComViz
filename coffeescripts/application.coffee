$(document).ready(() ->
  #Programme model
  Programme = Backbone.Model.extend({
    name: null,
    initialize:(options) ->
      #Bind the remove event to the destroy and delete the html element
      @bind("remove", () ->
        $('#'+this.cid).remove()

        @destroy()
      )
  })

  #Programmes collection
  Programmes = Backbone.Collection.extend({
    initialize: (models, options) ->
  })

  #Application view
  AppView = Backbone.View.extend({
    el: $("body"),
    initialize: () ->
      #Create a programme collection when the view is initialized, with a reference to this
      @programmes = new Programmes( null, { view: this })

      #Create our graph
      @graph = {}
      @graph.w = 960
      @graph.h = 500
      @graph.fill = d3.scale.category20()

      @vis = d3.select("#chart")
        .append("svg:svg")
          .attr("width", @graph.w)
          .attr("height", @graph.h)
      
      @data = {
        nodes: [],
        links: []
      }

      @redrawGraph()
    ,
    events: {
      "click #add_programme":  "programmeNamePrompt",
      "click a.delete_programme":  "deleteProgramme"
    },
    programmeNamePrompt: () ->
      programme_name = prompt("Programme name?")
      programme_model = new Programme({ name: programme_name })
      #Add a new programme model to our programmes collection
      @programmes.add( programme_model )
      @addProgramme(programme_model)
    ,
    deleteProgramme: (e) ->
      li = $(e.currentTarget).parent('li')
      f = @programmes.getByCid(li.attr('id'))
      this.programmes.remove(f)
      @data.nodes = @data.nodes.filter( (node) ->
        node.id != f.cid
      )
      @redrawGraph()
    ,
    addProgramme: (model) ->
      #The parameter passed is a reference to the model that was added
      $("#programme_list").append("<li id='#{model.cid}'>#{model.get('name')} <a href='#' class='delete_programme'>delete</a></li>")

      #Add the node to the graph
      @data.nodes.push({name:model.get('name'), id: model.cid})
      @redrawGraph()
    ,
    redrawGraph: () ->
      graph = @graph

      force = d3.layout.force()
        .charge(-120)
        .linkDistance(30)
        .nodes(@data.nodes)
        .links(@data.links)
        .size([@graph.w, @graph.h])
        .start()

      link = @vis.selectAll("line.link")
          .data(@data.links)
        .enter().append("svg:line")
          .attr("class", "link")
          .style("stroke-width", (d) -> return Math.sqrt(d.value) )
          .attr("x1", (d) ->  return d.source.x)
          .attr("y1", (d) ->  return d.source.y)
          .attr("x2", (d) ->  return d.target.x)
          .attr("y2", (d) ->  return d.target.y)

      #NODE DRAWING
      #first we create svg:g elements as the container
      node = @vis.selectAll("g.node")
          .data(@data.nodes, (d) -> d.id)
        .enter().append("svg:g")
          .attr("class", "node")
          .call(force.drag)
      
      #Then we fill the svg:g elements with:
      #The circle
      node.append("svg:circle")
          .attr("r", 5)
          .style("fill", "#234B6F")
          .attr("class", "circle")
          .attr("x", "-8px")
          .attr("y", "-8px")
          .attr("width", "16px")
          .attr("height", "16px")
      #The Name
      node.append("svg:text")
          .attr("class", "node_text")
          .attr("dx", 12)
          .attr("dy", ".35em")
          .text((d) -> d.name)
      
      #Remove nodes
      @vis.selectAll("g.node").data(@data.nodes, (d) -> d.id).exit().remove()

      @vis.style("opacity", 1e-6)
        .transition()
        .duration(1000)
        .style("opacity", 1)

      force.on("tick", () ->
        link.attr("x1", (d) ->  return d.source.x)
        .attr("y1", (d) ->  return d.source.y)
        .attr("x2", (d) ->  return d.target.x)
        .attr("y2", (d) ->  return d.target.y)

        node.attr("transform", (d) -> "translate(#{d.x},#{d.y})")
      )
  })

  window.appview = new AppView
)

