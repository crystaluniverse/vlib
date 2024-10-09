```yaml

!!webdb.user_add
    name: 'Kristof'
    email: 'kristof@incubaid.com'
    admin: true


!!webdb.user_add
    name: 'John Doe'
    email: 'john.doe@example.com'
    description: 'Senior Developer'
    profile: 'Technical'
    admin: false

!!webdb.user_add
    name: 'Someone'
    email: me@example.com'
    admin: false

!!webdb.user_add
    email: jane.smith@example.com'


!!webdb.group_add
    name: 'Developers'
    users: 'john.doe@example.com,jane.smith@example.com'
    groups: 'Frontend,Backend'

!!webdb.group_add
    name: 'Frontend'
    users: 'john.doe@example.com'
    groups: 'Frontend,Backend'

!!webdb.group_add
    name: 'Backend'


!!webdb.acl_add
    name: 'ProjectX_ACL'

!!webdb.ace_add
    acl: 'ProjectX_ACL'
    group: 'Developers'
    user: 'john.doe@example.com'
    right: 'write'

!!webdb.ace_add
    acl: 'ProjectX_ACL'
    user: 'Someone'
    right: 'read'

!!webdb.ace_add
    acl: 'public'
    right: 'read'


!!webdb.infopointer_add
    name: 'threefold_slides'
    hero_url: 'https://git.ourworld.tf/tfgrid/info_tfgrid/src/branch/development/collections/slides_threefold_depin'
    hero_url_pull: false
    hero_url_reset: false
    hero_path: '' #not needed here because comes from hero_url
    content_url: ''
    content_url_pull: false
    content_url_reset: false
    content_path: '~/hero/var/collections/slides_threefold_depin/img'
    acl: 'public'
    cat: 'slides'
    description: '
        This is a set of slides for threefold depin project.
    '
    expiration: '2024-12-31'
    
!!webdb.infopointer_add
    name: 'tech'
    hero_url: 'https://git.ourworld.tf/tfgrid/info_tfgrid/src/branch/development/heroscript/tech'
    hero_url_pull: false
    hero_url_reset: false
    content_path: '~/hero/www/info/tech'
    acl: 'public'
    cat: 'wiki'
    description: '
        Wiki for technology of threedold
    '

#will have 2 documents inside
!!webdb.infopointer_add
    name: 'threefoldoverview'
    acl: 'public'
    cat: 'wiki'
    children: 'tech,threefold_slides'
    description: '
        Lean more about ThreeFold Grid
    '    

#will have a document and a folder inside, threefoldoverview is a folder because has more than 1 file (is automatically a folder then)
!!webdb.infopointer_add
    name: 'threefoldoverview'
    acl: 'public'
    cat: 'wiki'
    children: 'tech,threefoldoverview'
    description: '
        Lean more about ThreeFold Grid
    '    


```