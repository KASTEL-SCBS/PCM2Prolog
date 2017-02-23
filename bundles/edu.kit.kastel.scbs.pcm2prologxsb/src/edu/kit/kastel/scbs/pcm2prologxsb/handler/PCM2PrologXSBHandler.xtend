package edu.kit.kastel.scbs.pcm2prologxsb.handler

import org.eclipse.core.resources.IFile
import edu.kit.ipd.sdq.commons.ecore2txt.util.Ecore2TxtUtil
import edu.kit.ipd.sdq.mdsd.ecore2log.config.UserConfiguration
import edu.kit.ipd.sdq.mdsd.ecore2log.handler.AbstractEcore2LogHandler
import edu.kit.kastel.scbs.pcm2prologxsb.generator.PCM2PrologXSBGenerator
import edu.kit.kastel.scbs.pcm2prologxsb.generator.PCM2PrologXSBGeneratorModule
import java.util.List

class PCM2PrologXSBHandler extends AbstractEcore2LogHandler {

	override executeEcore2TxtGenerator(List<IFile> files, UserConfiguration userConfiguration) {
		Ecore2TxtUtil.generateFromSelectedFilesInFolder(files,new PCM2PrologXSBGeneratorModule(),new PCM2PrologXSBGenerator(userConfiguration), userConfiguration.concatOutputToSingleFile(), userConfiguration.groupFacts())
	}

	override getPlugInID() '''edu.kit.kastel.scbs.pcm2prologxsb'''
}