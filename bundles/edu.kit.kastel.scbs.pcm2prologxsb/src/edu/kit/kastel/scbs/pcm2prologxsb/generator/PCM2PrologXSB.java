package edu.kit.kastel.scbs.pcm2prologxsb.generator;

import java.util.Map;

import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;

import edu.kit.ipd.sdq.mdsd.ecore2log.config.DefaultUserConfiguration;
import edu.kit.ipd.sdq.mdsd.ecore2txt.util.Ecore2TxtUtil;
import edu.kit.kastel.scbs.pcm2prologxsb.cli.PCM2PrologXSBCommandLineContent;
import edu.kit.kastel.scbs.pcm2prologxsb.cli.PCM2PrologxsbCLI;
import edu.kit.kastel.scbs.pcm2prologxsb.config.PrologXSBLogConfiguration;

public class PCM2PrologXSB implements IApplication {

	public static void main(String[] args) {
		PCM2PrologXSBCommandLineContent cliContent = new PCM2PrologxsbCLI().interrogateCommandLine(args);
		
		if(cliContent.isValid()) {
			DefaultUserConfiguration userConfiguration = cliContent.getDefaultUserConfiguration();
			Ecore2TxtUtil.generateFromSelectedFilesInFolder(cliContent.getFilesOfResourcePaths(),new PCM2PrologXSBGeneratorModule(),new PCM2PrologXSBGenerator(userConfiguration), userConfiguration.concatOutputToSingleFile(), userConfiguration.groupFacts());
		}
		
	}

	@Override
	public Object start(IApplicationContext context) throws Exception {
		Map<?, ?> contextArgs = context.getArguments();
		String[] appArgs = (String[]) contextArgs.get("application.args");
		
		
		PCM2PrologXSBCommandLineContent cliContent = new PCM2PrologxsbCLI().interrogateCommandLine(appArgs);
			
			
			
			
			if(cliContent.isValid()) {
				DefaultUserConfiguration userConfiguration = cliContent.getDefaultUserConfiguration();
				Ecore2TxtUtil.generateFromSelectedFilesInFolder(cliContent.getFilesOfResourcePaths(),new PCM2PrologXSBGeneratorModule(),new PCM2PrologXSBGenerator(userConfiguration), userConfiguration.concatOutputToSingleFile(), userConfiguration.groupFacts());
			} else {
				System.out.println("Error in CLI");
				System.exit(42);
				return 42;
			}
		
	
		System.out.println("Done");
		return IApplication.EXIT_OK;
	}

	@Override
	public void stop() {
		// TODO Auto-generated method stub
		
	}

}
