class window.Host

  knownFields: ['name', 'mac', 'pno']

  constructor: (data) ->
    @data = data

  toJSON: ->
    obj = {}
    @knownFields.forEach (e) =>
      if @data[e] != ""
        obj[e] = @data[e]
    obj

class window.Switch

  knownFields: ['name', 'mac', 'pno']

  constructor: (data) ->
    @data = data

  toJSON: ->
    obj = {}
    @knownFields.forEach (e) =>
      if @data[e] != ""
        obj[e] = @data[e]
    obj

class window.Link

  knownFields: ['source', 'target', 'port1', 'port2', 'bw', 'delay', 'loss']

  constructor: (data) ->
    @data = data

  toJSON: ->
    obj = {}
    @knownFields.forEach (e) =>
      if @data[e] != ""
        obj[e] = @data[e]
    obj


