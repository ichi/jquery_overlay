$win = $(window)
$html = $('html')
$body = $('body')


$.getPageSize ||= ()->
  [x_scroll, y_scroll] = switch
    when window.innerHeight && window.scrollMaxY
      [(window.innerWidth + window.scrollMaxX), (window.innerHeight + window.scrollMaxY)]
    when document.body.scrollHeight > document.body.offsetHeight
      [document.body.scrollWidth, document.body.scrollHeight]
    else
      [document.body.offsetWidth, document.body.offsetHeight]

  [win_w, win_h] = switch
    when self.innerHeight
      w = document.documentElement?.clientWidth || self.innerWidth
      [w, self.innerHeight]
    when document.documentElement?.clientHeight
      [document.documentElement.clientWidth, document.documentElement.clientHeight]
    when document.body
      [document.body.clientWidth, document.body.clientHeight]

  page_w = if x_scroll < win_w then x_scroll else win_w
  page_h = if y_scroll < win_h then win_h else y_scroll

  {
    page:
      width: page_w
      height: page_h
    window:
      width: win_w
      height: win_h
  }


$.Overlay = class Overlay
  @uid = 0
  @all = $([])
  @page_size = []

  # class methods ------------------------------
  @create = (settings)->
    new Overlay(settings)

  @getCenterPosition: (width_height..., position_fixed)->
    [width, height] = switch width_height.length
      when 0
        throw 'not enough arguments'
      when 1
        size = width_height[0]
        if $.isArray(size)
          size
        else
          [size, size]
      else
        width_height

    {
      top: (@page_size.window.height - height) / 2 + (if position_fixed then 0 else $win.scrollTop())
      left: (@page_size.window.width - width) / 2
    }

  @cssCenterPosition: ($elm, width_height..., position_fixed)->
    args = width_height.concat [position_fixed]
    $elm.css @getCenterPosition.apply(@, args)

  # constructor ------------------------------
  constructor: (settings)->
    self = @

    @status = 
      visible: false
      opend: false

    @on_open =
      always: false
      done: false
      fail: false
    @on_close =
      always: false
      done: false
      fail: false

    @settings = $.extend {
      bg_color: "#000000"
      opacity: 0.5
      fade_speed: 400
      overlay_class: "pageOverlay"
      close_on_click: true # true | false | Function
    }, settings

    page_size = Overlay.page_size = $.getPageSize()

    @id = @settings.overlay_class + Overlay.uid++

    # overlay
    @overlay = $('<div></div>').attr(
      class: @settings.overlay_class
      id: @id
    ).css(
      display: "none"
      width: page_size.window.width
      height: page_size.page.height
      position: "absolute"
      top: 0
      left: 0
      backgroundColor: @settings.bg_color
      opacity: 0
    )


    ## bind

    # resize
    $win.off('resize.overlay_resize').on 'resize.overlay_resize', (ev)->
      page_size = Overlay.page_size = $.getPageSize()
      Overlay.all.css(
        width: page_size.window.width
        height: page_size.page.height
      )

    # clickで閉じる
    if close_on_click = @settings.close_on_click
      @overlay.on 'click', (ev)=>
        promise = @close()
        promise.done close_on_click if $.isFunction(close_on_click)
          

    ## init
    @overlay.appendTo $('body')
    Overlay.all = Overlay.all.add @overlay


  # instance methods ------------------------------

  open: (speed)->
    self = @
    @_dfd_open = new $.Deferred()
    @_assign_callbacks(@_dfd_open, @on_open)

    unless @status.visible
      @_selects = $('select:visible').hide()

      @status.visible = true
      @overlay.show().fadeTo (speed || @settings.fade_speed), @settings.opacity, (args...)=>
        @status.opend = true
        @_dfd_open.resolve.apply(@_dfd_open, args)

    @_dfd_open.promise()

  close: (speed)->
    self = @
    @_dfd_close = new $.Deferred()
    @_assign_callbacks(@_dfd_close, @on_close)

    if @status.visible
      @_dfd_open.reject() unless @status.opend

      @status.opend = false
      @overlay.stop().fadeTo (speed || @settings.fade_speed), 0, (args...)=>
        @overlay.hide()
        @_selects.show()
        @status.visible = false;
        @_dfd_close.resolve.apply(@_dfd_close, args)

    @_dfd_close.promise()

  getCenterPosition: (args...)->
    Overlay.getCenterPosition.apply(Overlay, args)

  cssCenterPosition: (args...)->
    Overlay.cssCenterPosition.apply(Overlay, args)

  _assign_callbacks: (dfd, callbacks = {})->
    $.each callbacks, (name, callback)->
      dfd[name] callback

 
