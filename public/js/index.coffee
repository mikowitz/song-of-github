((global, $, MIDI) ->
  'use strict'

  names = global.names

  organizeData = (calendarData) ->
    weeks = []
    column = []
    d = new Date calendarData[0][0]
    dayOffset = d.getDay()

    calendarData = ([0, 0] for i in [0...dayOffset]).concat calendarData

    for cd, i in calendarData
      column.push calendarData[i][1]

      if i > 0 && ((i + 1) % 7 == 0)
        weeks.push column
        column = []
    
    weeks

  updateTD = (week, day, name) ->
    $("##{name} #visualize").find("tr:eq(#{day}) > td:eq(#{week})").css({opacity: 0.25})

  loadVisualization = (weeks, name) ->
    days = ($("##{name} #day#{i}") for i in [0..6])
    
    for week, n in weeks
      for w, m in week
        contrib = switch weeks[n][m]
          when 0 then 0
          when 1,2,3,4 then 1
          when 5,6,7,8,9 then 2
          when 10,11,12,13,14 then 3
          else 4

        days[m].append $("<td class='status#{contrib}'></td>")

  delay = 0
  loadSong = (weeks) ->
    MIDI.loadPlugin {
      instruments: [ 'acoustic_grand_piano' ],
      callback: () ->
        MIDI.programChange 0, 0
        MIDI.programChange 1, 118

        for w, n in weeks[0]
          delay = n
          for week, i in weeks
            playWeek week[n], n, names[i]
    }

  chords = {
    I:    [48, 52, 55, 60, 64, 67, 72],
    ii:   [50, 53, 57, 62, 65, 69, 74],
    iii:  [52, 55, 59, 64, 67, 71, 76],
    IV:   [41, 45, 48, 53, 57, 60, 65],
    V:    [43, 47, 50, 55, 59, 62, 67],
    vi:   [45, 48, 52, 57, 60, 64, 69],
    vii:  [47, 50, 53, 59, 62, 65, 71]
  }

  chordMap = (k for k, v of chords)

  playWeek = (week, n, name) ->
    note = 60
    noteDelay = 0
    sum = week.reduce(((t, n) -> t + n), 0)

    getChord = ->
      l = chordMap.length
      chords[chordMap[(sum ^ l) % (l - 1)]]

    getNote = ->
      note = chord[m]
      if (sum % 14 == 0) && (m % 3 == 0) then note + 1 else note

    getVelocity = -> 20 + (m * 4)

    getDelay = ->
      noteDelay = if arpeggio then delay + (m / chordMap.length - 1) else delay
      noteDelay
      
    chord = getChord()
    arpeggio = week[0] > 0

    for d, m in week
      if d > 0
        MIDI.noteOn(0, getNote(), getVelocity(), getDelay())
        if m > 5
          MIDI.noteOn(0, getNote(), getVelocity(), getDelay() * 0.5)

      ((n, m, name) ->
        window.setTimeout((() ->
          updateTD n, m, name
        ), noteDelay * 1000)
      )(n, m, name)

  $ ->
    allWeeks = []
    for name in names
      weeks = organizeData window[name]
      loadVisualization weeks, name
      allWeeks.push weeks

    loadSong(allWeeks) if allWeeks.length > 0

)(this, jQuery, MIDI)
