src = files([
    'gflow-dock.vala',
    'gflow-node.vala',
    'gflow-simple-node.vala',
    'gflow-simple-sink.vala',
    'gflow-simple-source.vala',
    'gflow-sink.vala',
    'gflow-source.vala',
])

gflow = library('gflow-'+api,
                src,
                dependencies: [glib, gobject],
                install: true)

gflow_inc = include_directories('.')
