class window.OnenetTemplates
  @node_popover =
    """
      <button data-node-name="{{ node.name }}" data-action="edit" type="button" class="btn onenet-node-popover-btn">
        <i class="glyphicon glyphicon-edit"></i>
      </button>
      <button data-node-name="{{ node.name }}" data-action="delete" type="button" class="btn btn-danger onenet-node-popover-btn">
        <i class="glyphicon glyphicon-trash"></i>
      </button>
    """

  @link_popover =
    """
      <button data-link-src="{{ link.source }}" data-link-dst="{{ link.target }}" data-action="edit" type="button" class="btn onenet-link-popover-btn">
        <i class="glyphicon glyphicon-edit"></i>
      </button>
      <button data-link-src="{{ link.source }}" data-link-dst="{{ link.target }}"data-action="delete" type="button" class="btn btn-danger onenet-link-popover-btn">
        <i class="glyphicon glyphicon-trash"></i>
      </button>
    """

  @node_edit_modal =
    """
      <div class="modal fade" role="dialog">
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header">
              <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
              <h4 class="modal-title">Editing: {{ node.name }}</h4>
            </div>
            <div class="modal-body">
              <form role="form">
                <div class="form-group">
                  <label for="nodeName">Name</label>
                  <input type="text" class="form-control" id="nodeName" value="{{ node.name }}">
                </div>
                <div class="form-group">
                  <label for="nodeMAC">MAC</label>
                  <input type="text" class="form-control" id="nodeMAC" value="{{ node.mac }}">
                </div>
              </form>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
              <button type="button" class="btn btn-primary onenet-editor-btn" data-action="save" data-fields="nodeName:name,nodeMAC:mac" data-save-to="node,{{ node.name }}">Save changes</button>
            </div>
          </div>
        </div>
      </div>
    """

  @link_edit_modal =
    """
      <div class="modal fade" role="dialog">
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header">
              <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
              <h4 class="modal-title">Editing: {{ link.source }} ⇄ {{ link.target }}</h4>
            </div>
            <div class="modal-body">
              <form role="form">
                <div class="form-group">
                  <label for="linkPort1">Port1</label>
                  <input type="text" class="form-control" id="linkPort1" value="{{ link.port1 }}">
                </div>
                <div class="form-group">
                  <label for="linkPort2">Port2</label>
                  <input type="text" class="form-control" id="linkPort2" value="{{ link.port2 }}">
                </div>
                <div class="form-group">
                  <label for="linkBW">Bandwidth</label>
                  <input type="text" class="form-control" id="linkBW" value="{{ link.bw }}">
                </div>
                <div class="form-group">
                  <label for="linkDelay">Delay</label>
                  <input type="text" class="form-control" id="linkDelay" value="{{ link.delay }}">
                </div>
                <div class="form-group">
                  <label for="linkLoss">Loss</label>
                  <input type="text" class="form-control" id="linkLoss" value="{{ link.loss }}">
                </div>
              </form>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
              <button type="button" class="btn btn-primary onenet-editor-btn" data-action="save" data-fields="linkPort1:port1,linkPort2:port2,linkBW:bw,linkDelay:delay,linkLoss:loss" data-save-to="link,{{ link.source }},{{ link.target }}">Save changes</button>
            </div>
          </div>
        </div>
      </div>
    """

  @log_entry =
    """
      <div class="log-entry" data-host="{{ host }}">
        <span class="label label-primary tag">{{ host }}</span><span class="log-text">{{ log }}</span>
      </div>
    """

