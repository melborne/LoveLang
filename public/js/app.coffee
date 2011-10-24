graph = (p) ->
  COLORS = [[200,0,0], [255, 40, 111], [255,127,0], [200,255,0], [127, 200, 0], [0,255,50], [0, 127, 255], [10,40,240], [111,0,255], [180,0,255], [200, 180, 100], [255, 40, 30]]
  p.setup = ->
    p.size($("body").width()/1.7, $("body").width()/1.7)
    p.background(255)    
    p.smooth()
    p.frameRate(5)
    $("button").each (i)->
      $(this).attr("style", "background-color:rgb(#{COLORS[i]})")

  p.draw = ->
    values = []
    p.background(255)
    $("button").each (i)->
      val = parseInt($(this).attr('cnt'))
      col = COLORS[i]
      lab = $(this).text()
      values.push [val, col, lab]

    drawCircleGraph(p.width-20, values)
    
  drawCircleGraph = (dia, values)->
    p.pushMatrix()
    p.translate(p.width/2, p.height/2)
    p.fill(255)
    p.ellipse(0, 0, dia, dia)
    p.rotate(-p.PI/2.0)
    
    total = values.map((v) -> v[0]).reduce((t, i) -> t + i)
    prev = 0
    for vcls, i in values
      [value, color, label] = vcls
      
      p.fill(color..., 220)
      p.stroke(90)
      p.strokeWeight(3)
      val = p.map(value, 0, total, 0, p.TWO_PI) or 0
      p.rotate(prev)
      p.arc(0, 0, dia, dia, 0, val+0.01)
      prev = val
      drawLabel(label, value, val, dia/2-20, 20)
    p.popMatrix()

  drawLabel = (label, value, val, x, y)->
    if val > 0.15
      p.fill(90)
      p.stroke(0)
      p.textSize(20)
      p.textAlign(p.RIGHT)
      p.text(label, x, y)
      p.textSize(16)
      p.text(value, x, y+18)
  
countup = (id, cnt)->
  $("button##{id}").attr('cnt', cnt)

countupAll = (data)->
  countup(id, cnt) for id, cnt of data

update_user_counter = (cnt)->
  $("#user_counter").val(cnt)

debug = (str)-> $("#debug").append("<p>#{str}</p>")

init = ->
  $.get '/initialize.json', (data)->
    countupAll(data)

  new Processing($("canvas")[0], graph)

  if Pusher
    pusher = new Pusher(Pusher.key)
    channel = pusher.subscribe(Pusher.channel)
    pchannel = pusher.subscribe(Pusher.pchannel)

    channel.bind 'countup', (data) ->
      countup(data.id, data.cnt)

    pchannel.bind 'pusher:subscription_succeeded', (members)->
      update_user_counter(members.count)

    pchannel.bind 'pusher:member_added', ()->
      update_user_counter(pchannel.members.count)
      
    pchannel.bind 'pusher:member_removed', ()->
      update_user_counter(pchannel.members.count)

$ ->
  init()

  $("button").click ->
    $.post '/enquete.json', { 'id' : this.id }

