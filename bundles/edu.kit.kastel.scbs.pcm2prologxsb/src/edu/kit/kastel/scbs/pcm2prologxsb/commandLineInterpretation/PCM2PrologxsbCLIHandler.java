package edu.kit.kastel.scbs.pcm2prologxsb.commandLineInterpretation;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;


import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.OptionBuilder;
import edu.kit.ipd.sdq.mdsd.ecore2log.config.DefaultUserConfiguration;

public class PCM2PrologxsbCLIHandler {
	
	
	public static final String SYSTEM_FILES = "system";
	public static final String REPOSITORY_FILES = "repository";
	public static final String ADVERSARY_FILES = "adversary";
	public static final String RESOURCE_ENVIRONMENT_FILES = "resourceEnvironment";
	public static final String ALLOCATION_FILES = "allocation";
	public static final String CONFIDENTIALITY_FILES = "confidentiality";
	public static final String GENERATE_COMMENTS_PARAMETER = "generateComments";
	public static final String GROUP_FACTS_PARAMETER = "groupFacts";
	public static final String SIMPLIFY_IDS_PARAMETER = "simplifyIDs";
	public static final String CONCAT_OUTPUT_TO_SINGLE_FILE_PARAMETER = "concatOutputToSingleFile";
	public static final String GENERATE_DESCRIPTIONS_PARAMETER = "generateDescriptions";
	
	
	public Options getOptions() {
		
		
		Options options = new Options();
	
		Option systems = OptionBuilder.withArgName(SYSTEM_FILES).hasArgs().withDescription("Paths to the PCM System Models").create(SYSTEM_FILES);
		Option repositories = OptionBuilder.withArgName(REPOSITORY_FILES).hasArgs().withDescription("Paths to the PCM Repository Models").isRequired().create(REPOSITORY_FILES);
		Option adversaries = OptionBuilder.withArgName(ADVERSARY_FILES).hasArg().withDescription("Paths to the Confidentiality for PCM Adversary Models").create(ADVERSARY_FILES);
		Option resourceEnvironments = OptionBuilder.withArgName(RESOURCE_ENVIRONMENT_FILES).hasArgs().withDescription("Paths to the PCM Resource Enviornment Models").create(RESOURCE_ENVIRONMENT_FILES);
		Option allocations = OptionBuilder.withArgName(ALLOCATION_FILES).withDescription("Paths to the PCM Allocation Models").hasArgs().create(ALLOCATION_FILES);
		Option confidentialities = OptionBuilder.withArgName(CONFIDENTIALITY_FILES).withDescription("Paths to the Confidentiality for PCM Confidentiality Specification Models").hasArgs().create(CONFIDENTIALITY_FILES);
		Option generateComments = OptionBuilder.withArgName(GENERATE_COMMENTS_PARAMETER).hasArg(false).withDescription("Whether Comments shall be generated").create(GENERATE_COMMENTS_PARAMETER);
		Option groupFacts = OptionBuilder.withArgName(GROUP_FACTS_PARAMETER).hasArg(false).withDescription("Whether facts shall be grouped according to files").create(GROUP_FACTS_PARAMETER);
		Option simplifyIDs = OptionBuilder.withArgName(SIMPLIFY_IDS_PARAMETER).hasArg(false).withDescription("Wheter ids shall be simplified or used as complex ID names").create(SIMPLIFY_IDS_PARAMETER);
		Option concatOutput = OptionBuilder.withArgName(CONCAT_OUTPUT_TO_SINGLE_FILE_PARAMETER).hasArg(false).withDescription("Wheter output should be provided as several prolog files or one large one").create(CONCAT_OUTPUT_TO_SINGLE_FILE_PARAMETER);
		Option generateDescriptions = OptionBuilder.withArgName(GENERATE_DESCRIPTIONS_PARAMETER).hasArg(false).withDescription("Wheter descriptions shall be provided or not").create(GENERATE_DESCRIPTIONS_PARAMETER);

		
		options.addOption(systems);
		options.addOption(repositories);
		options.addOption(adversaries);
		options.addOption(resourceEnvironments);
		options.addOption(allocations);
		options.addOption(confidentialities);
		options.addOption(generateDescriptions);
		options.addOption(generateComments);
		options.addOption(groupFacts);
		options.addOption(simplifyIDs);
		options.addOption(concatOutput);


		return options;
	}
	
	
	//TODO Not pretty, much copy and paste, refactor in future 
	public PCM2PrologXSBCommandLineContent interrogateCommandLine(CommandLine cmd) {
		
		if(cmd == null) {
			return new PCM2PrologXSBCommandLineContent();
		}
		
		List<String> paths = new ArrayList<String>();
		
		if(cmd.hasOption(SYSTEM_FILES)) {
			for(String values : cmd.getOptionValues(SYSTEM_FILES)) {
				paths.add(values);
			}
		}
		
		if(cmd.hasOption(REPOSITORY_FILES)) {
			for(String values : cmd.getOptionValues(REPOSITORY_FILES)) {
				paths.add(values);
			}
		}
		
		if(cmd.hasOption(ADVERSARY_FILES)) {
			for(String values : cmd.getOptionValues(ADVERSARY_FILES)) {
				paths.add(values);
			}
		}
		
		if(cmd.hasOption(RESOURCE_ENVIRONMENT_FILES)) {
			for(String values : cmd.getOptionValues(RESOURCE_ENVIRONMENT_FILES)) {
				paths.add(values);
			}
		}
		
		if(cmd.hasOption(ALLOCATION_FILES)) {
			for(String values : cmd.getOptionValues(ALLOCATION_FILES)) {
				paths.add(values);
			}
		}
		
		if(cmd.hasOption(CONFIDENTIALITY_FILES)) {
			for(String values : cmd.getOptionValues(CONFIDENTIALITY_FILES)) {
				paths.add(values);
			}
		}
		
		System.out.println("Paths:-----");
		for(String p : paths) {
			System.out.println(p);
		}
		System.out.println("Paths:-----");
		
		
		boolean generateComments = cmd.hasOption(GENERATE_COMMENTS_PARAMETER);
		boolean groupFacts = cmd.hasOption(GROUP_FACTS_PARAMETER);
		boolean simplifyIDs = cmd.hasOption(SIMPLIFY_IDS_PARAMETER);
		boolean concatOutputToSingleFile = cmd.hasOption(CONCAT_OUTPUT_TO_SINGLE_FILE_PARAMETER);
		boolean generateDescriptions = cmd.hasOption(GENERATE_DESCRIPTIONS_PARAMETER);
		
		final DefaultUserConfiguration userConfiguration = new DefaultUserConfiguration(generateComments, groupFacts, simplifyIDs, concatOutputToSingleFile, generateDescriptions);
		
		return new PCM2PrologXSBCommandLineContent(userConfiguration, paths);

	}
	
}
