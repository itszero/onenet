$ ->

  # init d3
  initFunc = ->
    top = $('.header').height()
    width = $('#canvas-container').width()
    height = $('#canvas-container').height() - top
    if width <= 0 || height <= 0
      setTimeout initFunc, 100
    else
      window.onenet_controller = new OnenetController(width, height, top)

  setTimeout initFunc, 100

  # toolbar
  $(".toolbar-button").click (e) ->
    if ($(this).is("[data-toggle='toggle']"))
      $(this).parent('.toolbar').find('.toolbar-button').removeClass('active')
      $(this).addClass('active')

    if ($(this).is("[data-action]"))
      window.onenet_controller[$(this).attr('data-action')].call(window.onenet_controller);

    if ($(this).is("[data-mode]"))
      window.onenet_controller.setMode($(this).attr('data-mode'))

$ ->
  editor_exp = ace.edit("editor-exp")
  editor_controller = ace.edit("editor-controller")

  [editor_exp, editor_controller].forEach (editor) ->
    editor.setTheme("ace/theme/solarized_dark")
    editor.getSession().setMode("ace/mode/python")

  editor_exp.getSession().setValue("from onenet.util import dumpNetConnections\n\ndumpNetConnections(net)\n")
  editor_controller.getSession().setValue("from pox.core import core\nimport pox.openflow.libopenflow_01 as of\nfrom pox.lib.util import dpidToStr\n\nlog = core.getLogger()\n\ndef _handle_ConnectionUp (event):\n  msg = of.ofp_flow_mod()\n  msg.actions.append(of.ofp_action_output(port = of.OFPP_FLOOD))\n  event.connection.send(msg)\n  log.info(\"Hubifying %s\", dpidToStr(event.dpid))\n\ndef launch ():\n  core.openflow.addListenerByName(\"ConnectionUp\", _handle_ConnectionUp)\n\n  log.info(\"Hub running.\")\n")

