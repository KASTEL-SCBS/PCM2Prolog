package edu.kit.kastel.scbs.pcm2prologxsb.cli;

import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.core.internal.resources.Project;
import org.eclipse.core.internal.resources.Workspace;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IWorkspaceRoot;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.core.runtime.Path;

import com.google.common.io.Files;

import edu.kit.ipd.sdq.mdsd.ecore2log.config.DefaultUserConfiguration;

public class PCM2PrologXSBCommandLineContents {
	private DefaultUserConfiguration userconfiguration;
	private List<IFile> resources;
	private List<String> resourcePaths;
	
	public PCM2PrologXSBCommandLineContents(DefaultUserConfiguration configuration, List<String> resourcePaths) {
		this.userconfiguration = configuration;
		this.resourcePaths = resourcePaths;
		resources = new ArrayList<IFile>();
	}
	
	
	public DefaultUserConfiguration getDefaultUserConfiguration() {
		return userconfiguration;
	}
	
	public List<String> getResourcePaths(){
		return resourcePaths;
	}
	
	public List<IFile> getFilesOfResourcePaths(){
		String workspaceLocation = ResourcesPlugin.getWorkspace().getRoot().getLocation().toString();
		if(resourcesInitializationRequired()) {
			resources.clear();
			for(String path : resourcePaths) {
				File file = new File(path);
				IFile workspaceFile = null;
				URI location = file.toURI();
				if(!path.contains(workspaceLocation)) {
					IProgressMonitor progressMonitor = new NullProgressMonitor();
					IWorkspaceRoot root = ResourcesPlugin.getWorkspace().getRoot();
					IProject project = root.getProject("tmpProject");
					try {
						project.create(progressMonitor);
					} catch (CoreException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
					
					String tmpFolderLocation = workspaceLocation + "/" + "tmpProject" + "/" + "tmpFolder";
					File tmpFolder = new File(tmpFolderLocation);
					tmpFolder.mkdirs();
					
					File destinationFile = new File(tmpFolderLocation + "/");
					try {
						Files.copy(file, destinationFile);
					} catch (IOException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
				}
				
				IFile[] files = ResourcesPlugin.getWorkspace().getRoot().findFilesForLocationURI(location);
				if(files.length > 0) {
					workspaceFile = files[0];
				}
				resources.add(workspaceFile);
				
			}
		}
		
		return resources;
	}
	
	private boolean resourcesInitializationRequired() {
		return !(resources.size() == resourcePaths.size());
	}
	

	
}
