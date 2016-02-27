workspace 'AsyncOpKit'

use_frameworks!
inhibit_all_warnings!

source 'https://github.com/CocoaPods/Specs.git'

project 'AsyncOpKit'

target "AsyncOpKitTests" do
   project 'AsyncOpKit'
   platform :ios, "9.0"
   pod 'Quick'
   pod 'Nimble'
end


post_install do |installer|

   workspace_name = 'AsyncOpKit'
   installer.pods_project.targets.each do |target|
       target.build_configurations.each do |config|
           if config.name == "Debug"
               config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
               else
               config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Owholemodule'
           end
       end
   end


   # identify projects that should be in workspace
   
   # run pod install for all pods
   # as long as the pod isn't at our current path
   # (to avoid one form of infinite loop)
   
   development_pods_projects = installer.sandbox.development_pods.flat_map do |k, v|
       root_proj_path = Pathname.new(v + "/" + k + ".xcodeproj")
       nested_proj_path = Pathname.new(v + "/" + k + "/" + k + ".xcodeproj")
       if Dir.exists?(root_proj_path)
           root_proj_path
           else Dir.exists?(nested_proj_path)
           nested_proj_path
       end
   end
   
   user_project_paths = installer.aggregate_targets.map { |at| at.user_project_path }.uniq
   
   all_allowed_projects = (development_pods_projects + user_project_paths + [installer.sandbox.project_path]).uniq
   
   workspace_path = Pathname.new(workspace_name + ".xcworkspace")
   
   file_references = all_allowed_projects.map { |proj| proj.relative_path_from(Pathname.getwd)}.map { |proj| Xcodeproj::Workspace::FileReference.new(proj) }
   
   if workspace_path.exist?
       workspace = Xcodeproj::Workspace.new_from_xcworkspace(workspace_path)
       unless workspace.file_references == file_references
           workspace = Xcodeproj::Workspace.new(*file_references)
           workspace.save_as(workspace_path)
       end
       else
       workspace = Xcodeproj::Workspace.new(*file_references)
       workspace.save_as(workspace_path)
   end
   
   # run pod install for all dev checkouts
   development_pods_paths = installer.sandbox.development_pods.map { |k, v| v }.uniq
   development_pods_paths.each do |path|
       if FileUtils.pwd != path
           puts "\n### BEGIN pod install FOR " + path
           FileUtils.cd(path) {
               output = []
               r, io = IO.pipe
               fork do
                   Kernel.system("pod install", out: io, err: :out)
               end
               io.close
               r.each_line{|l| puts l; output << l.chomp}
           }
           puts "### END pod install FOR " + path + "\n\n"
       end
   end
end
