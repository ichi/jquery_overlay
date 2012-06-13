$.pageSize ||= ()->
  [x_scroll, y_scroll] = switch
    when window.innerHeight && window.scrollMaxY
      [(window.innerWidth + window.scrollMaxX), (window.innerHeight + window.scrollMaxY)]
    when document.body.scrollHeight > document.body.offsetHeight
      [document.body.scrollWidth, document.body.scrollHeight]
    else
      [document.body.offsetWidth, document.body.offsetHeight]

  [win_w, win_h] = switch
    when self.innerHeight
      w = if document.documentElement.clientWidth
        document.documentElement.clientWidth
      else
        self.innerWidth
      [w, self.innerHeight]
    when document.documentElement?.clientHeight
      [document.documentElement.clientWidth, document.documentElement.clientHeight]
    when document.body
      [document.body.clientWidth, document.body.clientHeight]

  page_w = if x_scroll < win_w then x_scroll else win_w
  page_h = if y_scroll < win_h then win_h else y_scroll

  [page_w, page_h, win_w, win_h]


$.Overlay = class Overlay
  @uid = 0
  @all = $([])
  @page_size = []

  # class methods ------------------------------
  @create = (settings)->
    new Overlay(settings)

  # constructor ------------------------------
  constructor: (settings)->
    self = @

    @_opening = false
    @_opend = false

    @settings = $.extend {
      bg_color: "#000000"
      opacity: 0.5
      fade_speed: 400
      overlay_class: "pageOverlay"
      close_on_click: true # true|falseか、this.closeへの引数（引数が複数なら配列で）。
    }, settings

    page_size = Overlay.page_size = $.pageSize()

    @id = @settings.overlay_class + Overlay.uid++

    # overlay
    @overlay = $('<div></div>').attr(
      class: @settings.overlay_class
      id: @id
    ).css(
      display: "none"
      width: page_size[2] # win_w
      height: page_size[1] # page_h
      position: "absolute"
      top: 0
      left: 0
      backgroundColor: @settings.bg_color
      opacity: 0
    )

    # bind
    $(window).unbind('resize.overlay_resize').bind 'resize.overlay_resize', (ev)->
      page_size = Overlay.page_size = $.pageSize()
      Overlay.all.css(
        width: page_size[2] # win_w
        height: page_size[1] # page_h
      )
    if close_on_click = @settings.close_on_click
      @overlay.click (ev)->
        if close_on_click is true
          self.close()
        else
          self.close.apply self, $.makeArray(close_on_click)

    # init
    @overlay.appendTo $('body')
    Overlay.all.add @overlay


  # instance methods ------------------------------

  open: (speed, callback)->
    self = @

    unless @_opening
      [speed, callback] = [null, speed] if !callback && $.isFunction(speed)
      @selects = $('select:visible').hide()

      @_opening = true
      @overlay.show().fadeTo (speed || @settings.fade_speed), @settings.opacity, (args...)->
        @_opend = true
        callback.apply(@, args) if callback && $.isFunction(callback)

  close: (speed, callback)->
    self = @

    if @_opening
      [speed, callback] = [null, speed] if !callback && $.isFunction(speed)

      @_opend = false
      @overlay.stop().fadeTo (speed || @settings.fade_speed), 0, (args...)->
        self.overlay.hide()
        self.selects.show()
        self._opening = false;
        callback.apply(@, args) if callback && $.isFunction(callback)

  opening: ->
    @_opening

  opend: ->
    @_opend
  
