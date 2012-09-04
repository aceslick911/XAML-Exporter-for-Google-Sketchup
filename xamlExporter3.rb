=begin
 Xaml Exporter from Google SketchUp 
 Copyright (C) 2009 itaibh@gmail.com
  
 Install : Copy script to PLUGINS folder in SketchUp folder.
 Usage: Run SketchUp, go to Plugins > XAML > Export Model (or) Export Scene. Try loading your model in Xaml Viewer.
 
Feedback appreciated
   
=end

# add item if menu is not already loaded
if( $xamlExport_loaded != true ) then
	main_menu = UI.menu("Plugins").add_submenu("XAML")
	main_menu.add_item("Export Model...") { export_xaml_model }
	 main_menu.add_item("Export Scene...") { export_xaml_scene }
	$xamlExport_loaded = true
end

def export_xaml_model
	Sketchup.send_action "showRubyPanel:"
	print "exporting model to xaml\n"
	exp = XamlExporter.new
	exp.export_to_xaml false
	print "done!\n"
end

def export_xaml_scene
	Sketchup.send_action "showRubyPanel:"
	print "exporting scene to xaml\n"
	exp = XamlExporter.new
	exp.export_to_xaml true
	print "done!\n"
end

class XamlExporter

	def initialize
		@indent_level = 0
	end
	
	class HashablePoint3D
		def initialize (p3d, uv)
			#print "creating hashable point\n"
			@x=p3d.x
			@y=p3d.y
			@z=p3d.z
			@u=uv.x
			@v=uv.y
		end
			
		def eql? (b)
			res = (@x==b.x and @y==b.y and @z==b.z and @u=b.u and @v=b.v)
			#print "equl? a: #{to_s}\n"
			#print "      b: #{b.to_s} - #{res}\n"
			return res
		end
		
		def hash
			res = (@x * 1000000 + @y * 1000 + @z + @u * 10033 + @v * 1066).to_i
			#print "hash - #{to_s} : #{res}\n"
			return res
		end
		
		def to_pos_s
			res = "#{"%.4f" %(@x)} #{"%.4f" %(@y)} #{"%.4f" %(@z)}  "
			#print "to_pos_s #{res}"
			return res
		end
				
		def to_tex_s(w=1, h=1)
			res = "#{"%.6f" %(@u/w)} #{"%.6f" %(@v/h)}  "
			#print "to_tex_s #{res}"
			return res
		end
		
		def to_tex_s2()
			res = "#{"%.6f" %(@u)} #{"%.6f" %(-@v)}  "
			#print "to_tex_s #{res}"
			return res
		end
		
		def to_s
			return "#{"%.4f" %(@x)} #{"%.4f" %(@y)} #{"%.4f" %(@z)}  "
		end
		
		def x
			@x
		end
		
		def y
			@y
		end
		
		def z
			@z
		end
		
		def u
			@u
		end
		
		def v
			@v
		end
	end

	class Materials
		def initialize(face)
			@front=face.material
			@back=face.back_material
		end
		
		def front
			@front
		end
		
		def back
			@back
		end
		
		def eql? (b)
			res = (@front==b.front and @back==b.back)
			return res
		end
		
		def hash
			res = (@front.hash + @back.hash).to_i
			#print "hash - #{to_s} : #{res}\n"
			return res
		end
	end
	
	def export_to_xaml(scene)
		# call Save Dialog function
		@filename = get_xaml_filename
		if @filename == nil then # exit if cancel was choosen
			return
		end
		
		@fout = File.open(@filename, "w")
		@fout.puts xaml_title
		
		potential_namespaces = ""
		if scene == true then
			@fout.puts "<Viewport3D #{xaml_namespaces}>"
			indent
			write_camera
			write_lights
			@fout.puts "#{write_indent}<ModelVisual3D>"
			indent
			@fout.puts "#{write_indent}<ModelVisual3D.Content>"
			indent		
		elsif
			potential_namespaces = " #{xaml_namespaces}"
		end
		
		write_all_defenitions
		write_all_entities(potential_namespaces)
		
		if scene == true then
			unindent
			@fout.puts "#{write_indent}</ModelVisual3D.Content>"
			unindent
			@fout.puts "#{write_indent}</ModelVisual3D>"
			unindent
			@fout.puts "</Viewport3D>"
		end
		
		@fout.close
	end

	def write_camera
		print "writing camera\n"
		@fout.puts "#{write_indent}<Viewport3D.Camera>"
		indent
		cam = Sketchup.active_model.active_view.camera
		
		@fout.puts "#{write_indent}<PerspectiveCamera LookDirection=\"#{cam.direction.to_a.join(",")}\" Position=\"#{cam.eye.to_a.join(",")}\" UpDirection=\"#{cam.up.to_a.join(",")}\"/>"
		unindent
		@fout.puts "#{write_indent}</Viewport3D.Camera>"
	end
	
	def write_lights
		print "writing ambient light\n"
		@fout.puts "#{write_indent}<ModelVisual3D>"
		indent
		@fout.puts "#{write_indent}<ModelVisual3D.Content>"
		indent		
		@fout.puts "#{write_indent}<AmbientLight Color=\"#333333\"/>"
		unindent
		@fout.puts "#{write_indent}</ModelVisual3D.Content>"
		unindent
		@fout.puts "#{write_indent}</ModelVisual3D>"
	end
	
	def get_xaml_filename
		model = Sketchup.active_model
		model_filename = File.basename(model.path)
		if model_filename != ""
			model_name = model_filename.split(".")[0]
		else
			model_name = "Untitled"
		end
		model_name += ".xaml"
		return UI.savepanel("Export as", "", model_name)
	end
	
	def write_all_defenitions
		print "write_all_defenitions\n"
		for defenition in Sketchup.active_model.definitions
			print "Defenition: #{defenition.name}\n"
		end
	end

	def write_all_entities(potential_namespaces)
		print "write_all_entities\n"
		@fout.puts "#{write_indent}<Model3DGroup#{potential_namespaces}>\n"
		write_entities(Sketchup.active_model.entities)
		@fout.puts "#{write_indent}</Model3DGroup>\n"
	end

	def collect_related_faces(faces)
		hash = Hash.new()
		
		for face in faces
			mats = Materials.new(face)
			
			if (!hash.has_key?(mats))
				hash[mats] = []
			end		
			hash[mats].push(face)
		end
		
		return hash
	end

	def collect_unique_points(faces)
		print "Collecting unique points\n"
		points = []
		hash = Hash.new()
		point_count = 0
		tw = Sketchup.create_texture_writer
		for face in faces
			mesh = face.mesh 7
			uv_helper = face.get_UVHelper true, false, tw
		
			for i in (1 .. mesh.count_points)
				point = mesh.point_at(i)
				#print "point: #{point.to_s}\n"
				uvq = uv_helper.get_front_UVQ(point)
				#print "texture coordinate: #{uvq.to_s}\n"
				hpoint = HashablePoint3D.new(point, uvq)
				
				if (hash.has_key?(hpoint))
					points = hash[hpoint]
				else
					points = []
					hash[hpoint] = points
				end
				points.push(point_count)
				point_count = point_count + 1
			end
		end

		return hash
	end

	def write_entities(entities)
		faces = []
		for entity in entities
			#print "Entity: #{entity.entityID.to_s} : #{entity.class.to_s}\n"
			if (entity.class == Sketchup::Group)
				write_group(entity)
			elsif (entity.class == Sketchup::ComponentInstance)
				write_component_instance(entity)
			elsif (entity.class == Sketchup::Face)
				faces.push(entity)
			end
		end
		
		faces_by_materials = collect_related_faces(faces)
		for material in faces_by_materials.keys
			write_mesh(faces_by_materials[material], material)
		end
	end

	def write_group(group)
		print "Group #{group.name}\n"
		indent
		if (group.name.empty?)
			@fout.puts "#{write_indent}<Model3DGroup>\n"
		else
			@fout.puts "#{write_indent}<Model3DGroup x:Name=\"#{group.name}\">\n"
		end
		indent
		@fout.puts "#{write_indent}<Model3DGroup.Transform>\n"
		indent
		@fout.puts "#{write_indent}<MatrixTransform3D Matrix=\"#{group.transformation.to_a().join(",")}\" />\n"
		unindent
		@fout.puts "#{write_indent}</Model3DGroup.Transform>\n"
		unindent
		write_entities(group.entities)
		@fout.puts "#{write_indent}</Model3DGroup>\n"
		unindent
	end

	def write_component_instance(entity)
		print "Component Instance: #{entity.to_s}\n"
	end

	def store_material(faces, material, side)
		if material then
			if material.texture then
				ext = material.texture.filename.split('.').last
				print "  material texture: #{material.name}\n"
				texturewriter = Sketchup.create_texture_writer
				f = File.dirname(@filename) + "\\" + File.basename(material.name).gsub!('[','').gsub!(']','') +  "." + ext
				print "      writing to '#{f}'\n"
				texturewriter.load faces[0], side
				texturewriter.write faces[0], side, f
			else
				print "  material color: #{material.color}\n"
			end
		end
	end
	
	def write_mesh(faces, material)
		print "Writing mesh with material #{material}\n"

		store_material(faces, material.front, true)
		store_material(faces, material.back, false)
		
		indent
		@fout.puts "#{write_indent}<GeometryModel3D>\n"

		#mesh
		print "Writing mesh\n"
		indent
		@fout.puts "#{write_indent}<GeometryModel3D.Geometry>\n"
		indent
		@fout.puts "#{write_indent}<MeshGeometry3D\n"
		
		indent
		
		#returns a hash from each unique point to all indices that represent that point
		unique_points = collect_unique_points(faces)
		
		points_indices = Hash.new()
		
		#write positions and texture coordinates
		points_str = ""
		texture_str = ""
		point_index = 0
	
		for point in unique_points.keys
			points_indices[point] = point_index
			points_str = points_str + "#{conv_numeric point.x.to_s} #{conv_numeric point.y.to_s} #{conv_numeric point.z.to_s}  " #point.to_pos_s
			
			print "Point: #{conv_numeric point.x.to_s},#{conv_numeric point.y.to_s },#{conv_numeric point.z.to_s }"

			texture_str = texture_str + point.to_tex_s2
			point_index = point_index + 1
		end
		@fout.puts "#{write_indent}Positions=\"#{points_str}\"\n"
		@fout.puts "#{write_indent}TextureCoordinates=\"#{texture_str}\"\n"
		
		#write triangle indices
		base_idx = 0
		indices_str = ""
		for face in faces
			 indices_str = indices_str + write_face_trigs(base_idx, face, points_indices)
			 mesh = face.mesh 7
			 base_idx = base_idx + mesh.count_points
		end
		@fout.puts "#{write_indent}TriangleIndices=\"#{indices_str}\"/>"
		
		unindent
		unindent
		@fout.puts "#{write_indent}</GeometryModel3D.Geometry>\n"	
		unindent
		
		#materials
		write_one_material(material.front, "Material")
		write_one_material(material.back, "BackMaterial")
	
		@fout.puts "#{write_indent}</GeometryModel3D>\n"
		unindent
	end
	
	def conv_numeric(aunit)
		text = aunit.chomp('m')
	end

	def write_one_material(material, materialName)
		if material then
			if material.texture then
				ext = material.texture.filename.split('.').last
				f = File.basename(material.name).gsub!('[','').gsub!(']','') + "." + ext
				write_image_material(f, 1, 1, materialName)
				
				print "  texture size: #{material.texture.width}x#{material.texture.height}\n"
			else
				r = material.color.red
				g = material.color.green
				b = material.color.blue
				
				write_material(materialName, "#%02x%02x%02x" % [r, g, b])
			end
		else
			write_material(materialName, "White")
		end
	end

	def write_face_trigs(base_idx, face, points_indices)
		mesh = face.mesh 7
		
		tw = Sketchup.create_texture_writer
		uv_helper = face.get_UVHelper true, false, tw
		
		indices_str = ""
		for i in (1..mesh.count_polygons)
			polygon = mesh.polygon_at(i)
			idx0 = polygon[0].abs
			idx1 = polygon[1].abs
			idx2 = polygon[2].abs

			p0 = mesh.point_at(idx0)
			p1 = mesh.point_at(idx1)
			p2 = mesh.point_at(idx2)
			
			uvq0 = uv_helper.get_front_UVQ(p0)
			uvq1 = uv_helper.get_front_UVQ(p1)
			uvq2 = uv_helper.get_front_UVQ(p2)
			
			idx0 = points_indices[HashablePoint3D.new(p0, uvq0)]
			idx1 = points_indices[HashablePoint3D.new(p1, uvq1)]
			idx2 = points_indices[HashablePoint3D.new(p2, uvq2)]
			
			indices_str = indices_str + "#{idx0} #{idx1} #{idx2} "
		end
		
		return indices_str
	end

	def write_image_material(filename, width, height, materialType)
		print "writing ImageBrush material size #{width}x#{height}\n"
		indent
		@fout.puts "#{write_indent}<GeometryModel3D.#{materialType}>\n"
		indent
		@fout.puts "#{write_indent}<DiffuseMaterial Color=\"White\">\n"
		indent
		@fout.puts "#{write_indent}<DiffuseMaterial.Brush>\n"
		indent
		@fout.puts "#{write_indent}<ImageBrush ViewportUnits=\"Absolute\" Stretch=\"Fill\" TileMode=\"Tile\" ImageSource=\"#{filename}\" />"
		unindent
		@fout.puts "#{write_indent}</DiffuseMaterial.Brush>\n"
		unindent
		@fout.puts "#{write_indent}</DiffuseMaterial>\n"
		unindent
		@fout.puts "#{write_indent}</GeometryModel3D.#{materialType}>\n"
		unindent
	end
	
	def write_material(material_type, material_brush)
		indent
		@fout.puts "#{write_indent}<GeometryModel3D.#{material_type}>\n"
		indent
		@fout.puts "#{write_indent}<DiffuseMaterial Color=\"White\" Brush=\"#{material_brush}\"/>\n"
		unindent
		@fout.puts "#{write_indent}</GeometryModel3D.#{material_type}>\n"
		unindent
	end

	def xaml_title()
		text = "<!-- SketchUp 6 to Xaml (c)2009 Itai Bar-Haim, supports: faces, normals and textures -->"
	end

	def xaml_namespaces()
		text = "xmlns=\"http://schemas.microsoft.com/winfx/2006/xaml/presentation\" xmlns:x=\"http://schemas.microsoft.com/winfx/2006/xaml\""
	end

	def indent
		@indent_level +=  1
	end

	def unindent
		@indent_level -= 1
	end

	def write_indent
		str = "  " * @indent_level
		return str
	end

end