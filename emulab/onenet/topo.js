{
    "nodes": [{
        "name": "h1",
        "pno": 0,
        "ip": "10.0.1.1"
    }, {
        "name": "h2",
        "pno": 2,
        "ip": "10.0.1.2"
    }, {
        "name": "h3",
        "pno": 1,
        "ip": "10.0.1.3"
    }, {
        "name": "h4",
        "pno": 3,
        "ip": "10.0.1.4"
    }, {
        "name": "h5",
        "pno": 3,
        "ip": "10.0.1.5"
    }],
    "switches": [{
        "name": "s1",
        "pno": 0
    }, {
        "name": "s2",
        "pno": 2
    }, {
        "name": "s3",
        "pno": 1
    }, {
        "name": "s4",
        "pno": 3
    }, {
        "name": "s5",
        "pno": 3
    }],
    "links": [{
        "source": "s1",
        "target": "backbone"
    }, {
        "source": "s3",
        "target": "backbone"
    }, {
        "source": "s2",
        "target": "backbone"
    }, {
        "source": "s4",
        "target": "backbone"
    }, {
        "source": "h1",
        "target": "s1"
    }, {
        "source": "h3",
        "target": "s3"
    }, {
        "source": "h2",
        "target": "s2"
    }, {
        "source": "s4",
        "target": "h4"
    }, {
        "source": "s4",
        "target": "s5"
    }, {
        "source": "s5",
        "target": "h5"
    }],
    "code": {
        "experiment": "from onenet.util import dumpNetConnections\n\ndumpNetConnections(net)\nnet.get('h1').cmd('ping -c1 10.0.1.2')\nnet.get('h2').cmd('ping -c1 10.0.1.1')\nnet.iperf((net.get('h1'), net.get('h3')))\nnet.iperf((net.get('h3'), net.get('h4')))\n",
        "controller": "from pox.core import core\nimport pox.openflow.libopenflow_01 as of\nfrom pox.lib.util import dpidToStr\n\nlog = core.getLogger()\n\ndef _handle_ConnectionUp (event):\n  msg = of.ofp_flow_mod()\n  msg.actions.append(of.ofp_action_output(port = of.OFPP_FLOOD))\n  event.connection.send(msg)\n  log.info(\"Hubifying %s\", dpidToStr(event.dpid))\n\ndef launch ():\n  core.openflow.addListenerByName(\"ConnectionUp\", _handle_ConnectionUp)\n\n  log.info(\"Hub running.\")\n"
    }
}
