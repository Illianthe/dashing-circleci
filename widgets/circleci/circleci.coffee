class Dashing.Circleci extends Dashing.Widget
  @accessor 'friendly_ewt', ->
    "#{moment.duration(@get('estimated_wait_time')).format('h:mm:ss', { trim: false })}"

  @accessor 'ewt_level', ->
    if @get('estimated_wait_time') == 0
      'idle'
    else if @get('estimated_wait_time') >= 1 && @get('estimated_wait_time') < 600000
      'minor'
    else if @get('estimated_wait_time') >= 600000 && @get('estimated_wait_time') < 1800000
      'major'
    else if @get('estimated_wait_time') >= 1800000
      'critical'

  onData: (data) ->
    # Groups statuses into success/fail/neutral categories
    $.each(data.recent_builds, (i, build) =>
      build['indicator'] = switch build['status']
        when 'success', 'fixed' then 'success'
        when 'failed', 'no_tests', 'infrastructure_fail', 'timedout' then 'failed'
        else 'default'

      build['friendly_status'] = build['status'].replace(/_/g, ' ')
    )
