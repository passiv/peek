#= require peek/vendor/jquery.tipsy

requestId = null

getRequestId = ->
  if requestId? then requestId else $('#peek').data('request-id')

peekEnabled = ->
  $('#peek').length

updatePerformanceBar = (results) ->
  for key of results.data
    for label of results.data[key]
      $("[data-defer-to=#{key}-#{label}]").text results.data[key][label]
  $(document).trigger 'peek:render', [getRequestId(), results]

initializeTipsy = ->
  $('#peek .peek-tooltip, #peek .tooltip').each ->
    el = $(this)
    gravity = if el.hasClass('rightwards') || el.hasClass('leftwards')
      $.fn.tipsy.autoWE
    else
      $.fn.tipsy.autoNS

    el.tipsy
      gravity: gravity

toggleBar = (event) ->
  return if $(event.target).is ':input'

  if event.which == 96 && !event.metaKey
    wrapper = $('#peek')
    if wrapper.hasClass 'disabled'
      wrapper.removeClass 'disabled'
      document.cookie = "peek=true; path=/";
    else
      wrapper.addClass 'disabled'
      document.cookie = "peek=false; path=/";

fetchRequestResults = ->
  $.ajax '/peek/results',
    data:
      request_id: getRequestId()
    success: (data, textStatus, xhr) ->
      updatePerformanceBar data
    error: (xhr, textStatus, error) ->
      # Swallow the error

$(document).on 'keypress', toggleBar

$(document).on 'peek:update', initializeTipsy
$(document).on 'peek:update', fetchRequestResults

# Fire the event for our own listeners.
$(document).on 'pjax:end', (event, xhr, options) ->
  if xhr?
    requestId = xhr.getResponseHeader 'X-Request-Id'

  if peekEnabled()
    $(this).trigger 'peek:update'

# Also listen to turbolinks page change event
$(document).on 'page:change', ->
  if peekEnabled()
    $(this).trigger 'peek:update'

# Also listen to wiselinks page always event
$(document).ajaxSend (event, xhr, ajaxOptions) ->
  if ajaxOptions.headers?
    if ajaxOptions.headers['X-Wiselinks']
      $(this).trigger('peek:start')

$(document).ajaxSuccess (event, xhr, ajaxOptions) ->
  if xhr.getResponseHeader 'X-Wiselinks-URL'
    requestId = xhr.getResponseHeader 'X-Request-Id'

    if peekEnabled()
      $(this).trigger 'peek:update'
      $(this).trigger('peek:end')

$ ->
  if peekEnabled()
    $(this).trigger 'peek:update'
