[1mdiff --git a/chunk/chunk.gd b/chunk/chunk.gd[m
[1mindex 8429051..8148030 100644[m
[1m--- a/chunk/chunk.gd[m
[1m+++ b/chunk/chunk.gd[m
[36m@@ -15,34 +15,39 @@[m [mfunc _process(delta):[m
 			Network.clearMessage(msg)[m
 			return;[m
 [m
[32m+[m[32mfunc _addBlockInstance(blockInstance):[m
[32m+[m	[32mif blockInstance.faces & Main.FACES_RIGHT:[m
[32m+[m		[32mblockInstance.get_child(5).visible = false[m
[32m+[m	[32mif blockInstance.faces & Main.FACES_LEFT:[m
[32m+[m		[32mblockInstance.get_child(4).visible = false[m
[32m+[m	[32mif blockInstance.faces & Main.FACES_BACK:[m
[32m+[m		[32mblockInstance.get_child(3).visible = false[m
[32m+[m	[32mif blockInstance.faces & Main.FACES_FRONT:[m
[32m+[m		[32mblockInstance.get_child(2).visible = false[m
[32m+[m	[32mif blockInstance.faces & Main.FACES_BOTTOM:[m
[32m+[m		[32mblockInstance.get_child(1).visible = false[m
[32m+[m	[32mif blockInstance.faces & Main.FACES_TOP:[m
[32m+[m		[32mblockInstance.get_child(0).visible = false[m
[32m+[m[41m		[m
[32m+[m	[32mvar staticBody = StaticBody3D.new()[m
[32m+[m	[32mvar collisor = CollisionShape3D.new()[m
[32m+[m	[32mcollisor.shape = BoxShape3D.new()[m
[32m+[m	[32mstaticBody.collision_layer = 0x02;[m
[32m+[m	[32mstaticBody.collision_mask = 0;[m
[32m+[m	[32mstaticBody.add_child(collisor)[m
[32m+[m	[32mblockInstance.add_child(staticBody)[m
[32m+[m	[32mstaticBody.position = Vector3(0.5,0.5,0.5)[m
[32m+[m[41m		[m
[32m+[m	[32madd_child(blockInstance)[m
[32m+[m
 func receiveBlocksInstance(initialBlocksInstance):[m
[32m+[m	[32m$StaticBody3D/CollisionShape3D.disabled = true[m
[32m+[m	[32m$MeshInstance3D.visible = false[m
 	for i in range(len(initialBlocksInstance)):[m
 		var blockInstance = initialBlocksInstance[i][m
 		blocks[blockInstance.blockKey] = blockInstance[m
 		[m
[31m-		#if blockInstance.faces & Main.FACES_RIGHT:[m
[31m-		#	blockInstance.get_child(5).queue_free()[m
[31m-		#if blockInstance.faces & Main.FACES_LEFT:[m
[31m-		#	blockInstance.get_child(4).queue_free()[m
[31m-		#if blockInstance.faces & Main.FACES_BACK:[m
[31m-		#	blockInstance.get_child(3).queue_free()[m
[31m-		#if blockInstance.faces & Main.FACES_FRONT:[m
[31m-		#	blockInstance.get_child(2).queue_free()[m
[31m-		#if blockInstance.faces & Main.FACES_BOTTOM:[m
[31m-		#	blockInstance.get_child(1).queue_free()[m
[31m-		#if blockInstance.faces & Main.FACES_TOP:[m
[31m-		#	blockInstance.get_child(0).queue_free()[m
[31m-		[m
[31m-		var staticBody = StaticBody3D.new()[m
[31m-		var collisor = CollisionShape3D.new()[m
[31m-		collisor.shape = BoxShape3D.new()[m
[31m-		staticBody.collision_layer = 0x02;[m
[31m-		staticBody.collision_mask = 0;[m
[31m-		staticBody.add_child(collisor)[m
[31m-		blockInstance.add_child(staticBody)[m
[31m-		staticBody.position = Vector3(0.5,0.5,0.5)[m
[31m-		[m
[31m-		add_child(blockInstance)[m
[32m+[m		[32m_addBlockInstance(blockInstance)[m
 [m
 func mintBlock(blockPosition):[m
 	var position = {}[m
[36m@@ -69,5 +74,5 @@[m [mfunc _onMintBlock(data):[m
 			oldBlock.queue_free()[m
 		var blockInstance = Main.instanceBlock(blockInfo);[m
 		chunk.blocks[newBlockKey] = blockInstance[m
[31m-		chunk.add_child(blockInstance)[m
[32m+[m		[32mchunk._addBlockInstance(blockInstance)[m
 	block.queue_free()[m
[1mdiff --git a/chunk/chunk.tscn b/chunk/chunk.tscn[m
[1mindex 3f342af..73c6627 100644[m
[1m--- a/chunk/chunk.tscn[m
[1m+++ b/chunk/chunk.tscn[m
[36m@@ -1,4 +1,4 @@[m
[31m-[gd_scene load_steps=4 format=3 uid="uid://c4k07v18duecw"][m
[32m+[m[32m[gd_scene load_steps=5 format=3 uid="uid://c4k07v18duecw"][m
 [m
 [ext_resource type="Script" path="res://chunk/chunk.gd" id="1_mxemr"][m
 [m
[36m@@ -6,15 +6,24 @@[m
 size = Vector3(16, 16, 16)[m
 [m
 [sub_resource type="StandardMaterial3D" id="StandardMaterial3D_iefsr"][m
[31m-transparency = 1[m
[31m-albedo_color = Color(0.913725, 0.890196, 0.427451, 0.392157)[m
[32m+[m[32malbedo_color = Color(0.184314, 0.184314, 0.184314, 1)[m
[32m+[m
[32m+[m[32m[sub_resource type="BoxShape3D" id="BoxShape3D_b8pyk"][m
[32m+[m[32msize = Vector3(16, 16, 16)[m
 [m
 [node name="chunk" type="Node3D"][m
 script = ExtResource("1_mxemr")[m
 [m
 [node name="MeshInstance3D" type="MeshInstance3D" parent="."][m
 transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 8, 8, 8)[m
[31m-visible = false[m
 mesh = SubResource("BoxMesh_0ytf4")[m
 skeleton = NodePath("")[m
 surface_material_override/0 = SubResource("StandardMaterial3D_iefsr")[m
[32m+[m
[32m+[m[32m[node name="StaticBody3D" type="StaticBody3D" parent="."][m
[32m+[m[32mtransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 8, 8, 8)[m
[32m+[m[32mcollision_layer = 8[m
[32m+[m[32mcollision_mask = 0[m
[32m+[m
[32m+[m[32m[node name="CollisionShape3D" type="CollisionShape3D" parent="StaticBody3D"][m
[32m+[m[32mshape = SubResource("BoxShape3D_b8pyk")[m
[1mdiff --git a/player/player.gd b/player/player.gd[m
[1mindex ec77db9..d46eb44 100644[m
[1m--- a/player/player.gd[m
[1m+++ b/player/player.gd[m
[36m@@ -16,8 +16,8 @@[m [mconst JUMP_VELOCITY = 5.5[m
 # Mouse Control[m
 var mouse_sensitivity = 0.002[m
 var is_camera_first_person = true[m
[31m-var fly_mode = false[m
[31m-var start = false[m
[32m+[m[32mvar fly_mode = true[m
[32m+[m[32mvar start = true[m
 var mouse_vector = Vector2.ZERO[m
 [m
 func _ready():[m
[1mdiff --git a/player/player.tscn b/player/player.tscn[m
[1mindex b3bf2b9..c1a9d32 100644[m
[1m--- a/player/player.tscn[m
[1m+++ b/player/player.tscn[m
[36m@@ -10,7 +10,7 @@[m [mradius = 0.4[m
 height = 1.8[m
 [m
 [node name="player" type="CharacterBody3D"][m
[31m-collision_mask = 7[m
[32m+[m[32mcollision_mask = 15[m
 script = ExtResource("1_k21b6")[m
 [m
 [node name="CollisionShape3D" type="CollisionShape3D" parent="."][m
[1mdiff --git a/project.godot b/project.godot[m
[1mindex 811bc35..131dc79 100644[m
[1m--- a/project.godot[m
[1m+++ b/project.godot[m
[36m@@ -102,6 +102,7 @@[m [mchange_camera={[m
 3d_physics/layer_1="player"[m
 3d_physics/layer_2="blocks"[m
 3d_physics/layer_3="itens"[m
[32m+[m[32m3d_physics/layer_4="chunks"[m
 [m
 [rendering][m
 [m
[1mdiff --git a/world/world.tscn b/world/world.tscn[m
[1mindex 9c41a20..b2fc305 100644[m
[1m--- a/world/world.tscn[m
[1m+++ b/world/world.tscn[m
[36m@@ -22,7 +22,8 @@[m [msky = SubResource("Sky_eepef")[m
 script = ExtResource("1_juall")[m
 [m
 [node name="player" parent="." instance=ExtResource("1_ycrrn")][m
[31m-transform = Transform3D(-0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107, 15, 13, 13)[m
[32m+[m[32mtransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 8, 8, 8)[m
[32m+[m[32mcollision_mask = 0[m
 [m
 [node name="info" type="Label" parent="."][m
 offset_right = 59.0[m
