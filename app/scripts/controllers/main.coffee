"use strict"

onError = (error)->
  console.log error

controller = (params, scope, ngTableParams, $filter)->


  venueUid = parseInt params.venue, 10
  fromRank = parseFloat params.from
  toRank = parseFloat params.to
  refreshSeconds = parseInt params.refresh, 10

  userRating = Parse.Object.extend "UserRating"
  query = new Parse.Query userRating
  query.equalTo 'venueUid', venueUid
  scope.entities = []

  scope.availableRatings = (parseFloat(x.toFixed(1)) for x in [1.0..5.0] by 0.1)
  console.log scope.availableRatings

  alter = (data)->
    results = {}
    _.each data, (e)->
      key = e.get('objectType') + e.get('uid')
      unless results[key]
        results[key] =
          venueUid: e.get('venueUid')
          title: e.get('title')
          rating: e.get('rating')
          ratings: [e.get('rating')]
      else
        o = results[key]
        o.ratings.push e.get('rating')
        o.rating = _.reduce(o.ratings, (a,b)-> a+b) / o.ratings.length
        o.rating = parseFloat o.rating.toFixed(1)

    data = _.values results
    data = _.sortBy data, 'rating'
    console.log data
    data = _.filter data, (e)->
      fromRank < e.rating < toRank

    return data

  onSuccess = (data)->
    scope.entities = alter data
    console.log scope.entities
    scope.ratingsTable.reload()

  getData = ->
    scope.entities or []

  initTable = ->
    scope.ratingsTable = new ngTableParams(
      page: 1 # show first page
      count: 10 # count per page
      sorting:
        datetime: 'desc'
    ,
      total: ->
        getData().length # length of data

      getData: ($defer, params) ->
        data = getData()
        orderedData = (if params.filter() then $filter("filter")(data, params.filter()) else data)
        scope.list = orderedData?.slice((params.page() - 1) * params.count(), params.page() * params.count())
        # set total for recalc pagination
        params.total orderedData?.length
        $defer.resolve scope.list

        setTimeout ->
          scope.$apply ->
            $('.star').rating()
        , 100

      scope: {$data: {}}
    )


  load = ->
    query.find
      success: onSuccess
      error: onError

  load()
  initTable()


angular.module("tapwalkdevApp")
  .controller "MainCtrl", ['$routeParams', '$scope', 'ngTableParams', '$filter', controller]
