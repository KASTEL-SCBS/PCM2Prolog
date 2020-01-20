package edu.kit.kastel.scbs.pcm2prologxsb.commandLineInterpretation;

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

public class PCM2PrologXSBCommandLineContent {
	private DefaultUserConfiguration userconfiguration;
	private List<IFile> resources;
	private List<String> resourcePaths;
	private boolean tmpProjectIsCreated;

	public PCM2PrologXSBCommandLineContent(DefaultUserConfiguration configuration, List<String> resourcePaths) {
		this.userconfiguration = configuration;
		this.resourcePaths = resourcePaths;
		resources = new ArrayList<IFile>();
	}
	
	public PCM2PrologXSBCommandLineContent() {
		
	}
	
	public boolean isValid() {
		return resources != null && resourcePaths != null && userconfiguration != null;
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
				File file = null;
				try {
					file = new File(path).getCanonicalFile();
					System.out.println("Canonical Path" + file.getCanonicalPath());
				} catch (IOException e1) {
					System.out.println("Error in Cononical Path");
				}
				IFile workspaceFile = null;
				
				URI location = null;
				if(file != null) {
					location = file.toURI();
				}
				if(!path.contains(workspaceLocation)) {
					IProgressMonitor progressMonitor = new NullProgressMonitor();
					IWorkspaceRoot root = ResourcesPlugin.getWorkspace().getRoot();
					IProject project = root.getProject("PCM2PrologGenerate");
					
					if(!tmpProjectIsCreated) {
					try {
						project.create(progressMonitor);
						tmpProjectIsCreated = true;
					} catch (CoreException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
						}
					}
					
					try {
						project.open(progressMonitor);
					} catch (CoreException e1) {
						// TODO Auto-generated catch block
						e1.printStackTrace();
					}
					
					String[] splitPath = path.split("/");
					
					String fileName = splitPath[splitPath.length - 1];
					
					String generationFolderLocation = workspaceLocation + "/" + "PCM2PrologGenerate" + "/" + "generationFolder";
					File tmpFolder = new File(generationFolderLocation);
					if(!tmpFolder.exists()) {
						tmpFolder.mkdirs();
					}
					File destinationFile = new File(generationFolderLocation + "/" + fileName);
					try {
						Files.copy(file, destinationFile);
					} catch (IOException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
					
					location = destinationFile.toURI();
					
				} else {
					
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
