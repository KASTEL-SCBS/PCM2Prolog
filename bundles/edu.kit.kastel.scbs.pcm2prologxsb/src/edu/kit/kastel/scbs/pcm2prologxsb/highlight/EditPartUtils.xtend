/** 
 * Copyright (c) 2011 committers of YAKINDU and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * Contributors:
 * committers of YAKINDU - initial API and implementation
 */
package edu.kit.kastel.scbs.pcm2prologxsb.highlight

import java.util.ArrayList
import java.util.List
import org.eclipse.draw2d.Connection
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.gef.EditPart
import org.eclipse.gef.NodeEditPart
import org.eclipse.gmf.runtime.diagram.ui.editparts.IGraphicalEditPart

class EditPartUtils {
	@SuppressWarnings("unchecked") def static IGraphicalEditPart findEditPartForSemanticElement(EditPart editPart,
		EObject semanticElement) {
		if (semanticElement === null) {
			return null
		}
		if (editPart instanceof IGraphicalEditPart) {
			var EObject resolveSemanticElement = ((editPart as IGraphicalEditPart)).resolveSemanticElement()
			if (resolveSemanticElement !== null &&
				EcoreUtil.getURI(resolveSemanticElement).equals(EcoreUtil.getURI(semanticElement))) {
				return (editPart as IGraphicalEditPart)
			}
		}
		for (Object child : editPart.getChildren()) {
			var IGraphicalEditPart recursiveEditPart = findEditPartForSemanticElement((child as EditPart),
				semanticElement)
			if (recursiveEditPart !== null) {
				return recursiveEditPart
			}
		}
		if (editPart instanceof NodeEditPart) {
			var List<Connection> connections = new ArrayList<Connection>()
			connections.addAll(((editPart as NodeEditPart)).getSourceConnections())
			connections.addAll(((editPart as NodeEditPart)).getTargetConnections())
			for (Object connection : connections) {
				var EObject resolveSemanticElement = ((connection as IGraphicalEditPart)).resolveSemanticElement()
				if (EcoreUtil.equals(resolveSemanticElement, semanticElement)) {
					return (connection as IGraphicalEditPart)
				}
			}
		}
		return null
	}
}
