#
# Copyright (C) 2014 CAS / FAMU
#
# This file is part of Narra Core.
#
# Narra Core is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Narra Core is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Narra Core. If not, see <http://www.gnu.org/licenses/>.
#
# Authors: Michal Mocnak <michal@marigan.net>
#

angular.module('narra.ui').controller 'ProjectsDetailCtrl', ($scope, $rootScope, $document, $routeParams, $location, $filter, $q, dialogs, apiProject, apiUser, elzoidoPromises, elzoidoMessages, elzoidoAuthUser) ->
  $scope.refresh = ->
    # get current user
    $scope.user = elzoidoAuthUser.get()
    # get deffered
    project = $q.defer()

    apiProject.get {name: $routeParams.project}, (data) ->
      _.forEach(data.project.libraries, (library) ->
        library.thumbnails = [] if _.isUndefined(library.thumbnails)
        while library.thumbnails.length < 5
          library.thumbnails.push('/images/bars.png'))
      data.project.metadata = _.filter(data.project.metadata, (meta) ->
        !_.isEqual(meta.name, 'public')
      )
      $scope.project = data.project
      project.resolve true

    # register promises into one queue
    elzoidoPromises.register('project', [project.promise])
    # show wait dialog when the loading is taking long
    elzoidoPromises.wait('project', 'Loading project ...')

  $scope.edit = ->
    confirm = dialogs.create('partials/projectsInformationEdit.html', 'ProjectsInformationEditCtrl',
      {project: $scope.project},
      {size: 'lg', keyboard: false})
    # result
    confirm.result.then (wait) ->
      wait.result.then (project)->
        # fire event
        $rootScope.$broadcast 'event:narra-project-updated', project.name

  $scope.delete = ->
    # open confirmation dialog
    confirm = dialogs.confirm('Please Confirm',
      'You are about to delete the project ' + $scope.project.title + ', this procedure is irreversible. Do you want to continue ?')

    # result
    confirm.result.then ->
      # delete storage and its projects
      apiProject.delete {name: $scope.project.name}, ->
        # redirect back to libraries
        $location.url('/projects/')
        # send message
        elzoidoMessages.send('success', 'Success!', 'Project ' + $scope.project.name + ' was successfully deleted.')

  # click function for detail view
  $scope.detail = (library, index) ->
    $location.url('/libraries/' + library.id + '?project=' + $scope.project.name + '&from=libraries-' + index)

  # refresh when new library is added
  $scope.$on 'event:narra-library-created', (event) ->
    if !_.isUndefined($routeParams.project)
      $scope.refresh()

  $scope.$on 'event:narra-render-finished', ->
    if !_.isEmpty($location.hash())
      $document.duScrollToElement(document.getElementById($location.hash()))

  # refresh when new library is added
  $scope.$on 'event:narra-project-updated', (event, project) ->
    if _.isEqual($routeParams.project, project)
      $scope.refresh()

  # initial data
  $scope.refresh()