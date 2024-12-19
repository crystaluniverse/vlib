# ModelGenerator

- a tool which takes dir as input
    - is just some v files which define models
- outputs a generated code dir with
    - heroscript to memory for the model
    - supporting v script for manipulated model
    - name of actor e.g. ProjectManager, module would be project_manager

## how does the actor work

- is a global e.g. projectmanager_factory
- with double map
  - key1: cid
  - object: ProjectManager Object

- Object: Project Manager
  - has as properties:
    - db_$rootobjectname which is map
        - key: oid
        - val: the Model which represents the rootobject

- on factory
   - actions_process
         - process heroscript through path or text (params)
   - action_process
         - take 1 action as input
   - ${rootobjectname}_export
         - export all known objects as heroscript in chosen dir
         - name of heroscript would be ${rootobjectname}_define.md
   - ${rootobjectname}_get(oid)
       - returns rootobject as copy
   - ${rootobjectname}_list()!
       - returns list as copy
   - ${rootobjectname}_set(oid,obj)!
   - ${rootobjectname}_delete(oid)!
   - ${rootobjectname}_new()!

- in action we have
   - define
   - export/import
   - get
   - list


