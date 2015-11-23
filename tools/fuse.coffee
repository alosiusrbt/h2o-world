fs = require 'fs'
fp = require 'path'
fse = require 'fs-extra'
jade = require 'jade'
marked = require 'marked'
yaml = require 'js-yaml' 
dateformat = require 'dateformat'
underscore = require 'underscore'
highlight = require 'highlight.js'

SIM = no

SITEMAP_XML = '''
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
{{urls}}
</urlset>
'''

RSS_XML = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"
	xmlns:content="http://purl.org/rss/1.0/modules/content/"
	xmlns:wfw="http://wellformedweb.org/CommentAPI/"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:atom="http://www.w3.org/2005/Atom"
	xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
	xmlns:slash="http://purl.org/rss/1.0/modules/slash/"
	xmlns:georss="http://www.georss.org/georss" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:media="http://search.yahoo.com/mrss/"
  >
<channel>
  <title>0xdata Blog</title>
  <atom:link href="http://0xdata.com/blog/feed-{{category}}.xml" rel="self" type="application/rss+xml" />
  <link>http://0xdata.com/blog/</link>
  <description>The blog about H2O - The Open Source In-Memory Prediction Engine for Big Data Science</description>
  <lastBuildDate>{{date}}</lastBuildDate>
  <language>en</language>
  <sy:updatePeriod>daily</sy:updatePeriod>
  <sy:updateFrequency>1</sy:updateFrequency>
  <generator>http://0xdata.com/</generator>
  <image>
    <url>http://0xdata.com/assets/images/h2o.png</url>
		<title>0xdata Blog</title>
    <link>http://0xdata.com/blog/</link>
	</image>
  {{items}}
</channel>
</rss>
'''

RSS_XML_ITEM = '''
<item>
  <title><![CDATA[{{title}}]]></title>
  <link>{{permalink}}</link>
  <pubDate>{{date}}</pubDate>
  <guid isPermaLink="true">{{permalink}}</guid>
  <description><![CDATA[{{content}}]]></description>
  <content:encoded><![CDATA[{{content}}]]></content:encoded>
</item>
'''

marked.setOptions
  smartypants: yes
  highlight: (code, lang) ->
    (highlight.highlightAuto code, [ lang ]).value

isYaml = (ext) -> ext.toLowerCase() is '.yml'
isJade = (ext) -> ext.toLowerCase() is '.jade'
isMarkdown = (ext) -> ext.toLowerCase() is '.md'
isContent = (ext) -> (isMarkdown ext) or (isJade ext)
readFile = (path) -> fs.readFileSync path, 'utf8'
writeFile = fse.outputFileSync
copyFile = fse.copySync

formBin = (src) ->
  if isContent src.ext
    if src.dir is '.' and (src.slug is 'index' or src.slug is '404')
      path: fp.join src.dir, "#{src.slug}.html"
    else
      if 0 < src.slug.indexOf '_'
        tokens = src.slug.split /_+/g
        tokens.unshift src.dir
        tokens.push 'index.html'
        path: fp.join.apply null, tokens
      else
        path: fp.join src.dir, src.slug, 'index.html'
  else
    path: src.path

#TODO turn this into a plugin
createSitemapTxt = (targetDir, urls) ->
  writeFile (fp.join targetDir, 'sitemap.txt'), urls.join '\n'

#TODO turn this into a plugin
createSitemapXml = (targetDir, urls) ->
  writeFile (fp.join targetDir, 'sitemap.xml'), SITEMAP_XML.replace '{{urls}}', (urls.map (url) -> "<url><loc>#{url}</loc></url>").join '\n'

createCategorySlug = (category) ->
  category
    .toLowerCase()
    .replace /[^a-z0-9 ]/g, ''
    .replace /\s+/g, '-'

#TODO turn this into a plugin
createRSSFeeds = (targetDir, baseUri, tree) ->
  postsByCategory = all: []
  for name, child of tree 
    if child.src and isMarkdown child.src.ext
      if -1 is child.content.indexOf '<![CDATA['
        postsByCategory.all.push child
        if child.categories and child.categories instanceof Array
          for category in child.categories
            categorySlug = createCategorySlug category
            postsByCategory[categorySlug] = [] unless postsByCategory[categorySlug]
            postsByCategory[categorySlug].push child

  for categorySlug, posts of postsByCategory
    posts = posts.sort((a, b) -> b.date - a.date).slice 0, 10
    items = ''
    for post in posts
      item = RSS_XML_ITEM
      item = item.replace '{{title}}', post.title.replace /\<.+?\>/g, ''
      item = item.replace /\{\{permalink\}\}/g, 'http://0xdata.com' + post.url
      item = item.replace '{{date}}', post.date.toUTCString()
      item = item.replace /\{\{content\}\}/g, post.content
      items += item
    rss = RSS_XML.replace('{{date}}', new Date().toUTCString()).replace('{{category}}', categorySlug).replace '{{items}}', items
    writeFile (fp.join targetDir, "feed-#{categorySlug}.xml"), rss

  return

_templates = {}
loadTemplate = (path, cache=yes) ->
  if cache and template = _templates[path]
    template
  else
    template = jade.compileFile path,
      filename: path
    if cache
      _templates[path] = template
    template

forEachPage = (node, go) ->
  for name, child of node
    if child.__fuse__
      go node, child
    else
      forEachPage child, go
  return

walkSources = (sourceDir, currentDir, node) ->
  for name in (fs.readdirSync currentDir) when name[0] isnt '.'
    path = fp.join currentDir, name
    stat = fs.statSync path
    if stat.isDirectory() or stat.isFile()
      relpath = fp.relative sourceDir, path
      if stat.isDirectory()
        if name isnt '_templates'
          node[name] = leaf = {}
          walkSources sourceDir, path, leaf
      else
        ext = fp.extname path
        slug = fp.basename path, ext
        dir = fp.dirname relpath

        src =
          dir: dir
          slug: slug 
          ext: ext
          path: relpath

        bin = formBin src
        path = bin.path.split fp.sep
        path.pop() if path[path.length - 1] is 'index.html'

        unless (isContent ext) and slug[0] is '_' and not slug is '_sidebar'
          node[name] =
            __fuse__: yes
            src: src
            bin: bin
            ext: if ext[0] is '.' then (ext.substr 1).toLowerCase() else ext.toLowerCase()
            url: '/' + path.join '/' 
            path: path
  node

fuse = (context, sourceDir, targetDir) ->
  unless fs.existsSync sourceDir
    throw new Error 'Source directory does not exist: ' + sourceDir

  unless fs.statSync(sourceDir).isDirectory()
    throw new Error 'Not a directory: ' + sourceDir

  tree = walkSources sourceDir, sourceDir, {}

  tree.find = (path) ->
    node = tree
    for slug in path
      unless node = node[slug]
        return null
    node

  console.log 'Parsing files...'

  forEachPage tree, (parent, item) ->
    sourcePath = fp.join sourceDir, item.src.path
    if isMarkdown item.src.ext
      console.log 'Parsing ' + sourcePath
      content = readFile sourcePath
      if content[0 ... 3] is '---'
        result = content.match /^-{3,}\s([\s\S]*?)-{3,}(\s[\s\S]*|\s?)$/
        if result?.length is 3
          [ match, metadata, markdown ] = result
        else
          markdown = content
      else
        markdown = content

      if metadata
        properties = yaml.safeLoad metadata
        for k, v of properties
          item[k] = if k is 'date' then new Date v else v

      if markdown
        item.content = marked markdown
      
    else if isYaml item.src.ext
      console.log 'Parsing ' + sourcePath
      item.content = yaml.safeLoad readFile sourcePath

  console.log 'Building site...'

  forEachPage tree, (parent, page) ->
    if isMarkdown page.src.ext
      if page.src.slug[0] isnt '_'
        console.log 'Processing: ' + page.src.path
        template = loadTemplate fp.join sourceDir, '_templates', "#{page.template or 'default'}.jade" #TODO
        html = template
          context: context
          pages: tree
          page: page

        binPath = fp.join targetDir, page.bin.path
        console.log "#{page.src.path} --> #{binPath}"
        writeFile binPath, html unless SIM

    else if isJade page.src.ext 
      if page.src.slug[0] isnt '_'
        console.log 'Processing: ' + page.src.path
        
        sourcePath = fp.join sourceDir, page.src.path
        render = loadTemplate sourcePath, no
        page.content = render
          context: context
          pages: tree
          page: page

        template = loadTemplate fp.join sourceDir, '_templates', 'default.jade' #TODO
        html = template
          context: context
          pages: tree
          page: page
          
        binPath = fp.join targetDir, page.bin.path
        console.log "#{page.src.path} --> #{binPath}"
        writeFile binPath, html unless SIM
    else
      console.log 'Copying: ' + page.src.path
      srcPath = fp.join sourceDir, page.src.path
      binPath = fp.join targetDir, page.bin.path
      console.log "#{srcPath} --> #{binPath}"
      copyFile srcPath, binPath unless SIM

  if SIM
    console.log 'Dumping...'
    writeFile 'fuse.dump', JSON.stringify tree, null, 2 


  urls = []
  forEachPage tree, (parent, page) ->
    if isContent page.src.ext
      urls.push 'http://h2oworld.h2o.ai' + page.url

  console.log 'Creating sitemaps...'
  createSitemapTxt targetDir, urls
  createSitemapXml targetDir, urls

  console.log 'Done!'

[ runtime, script, sourceDir, targetDir ] = process.argv

context =
  underscore: underscore
  formatDate: dateformat

fuse context, sourceDir, targetDir

return
