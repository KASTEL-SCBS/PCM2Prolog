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

import java.util.Collections
import java.util.List
import org.eclipse.emf.ecore.EObject

/** 
 * @author Alexander Nyssen
 * @author Andreas Muelder
 */
interface IHighlightingSupport {
	def void lockEditor()

	def boolean isLocked()

	def void releaseEditor()

	def void highlight(List<? extends EObject> semanticElement, HighlightingParameters parameters)

	def void executeAsync(List<Action> actions)

	static interface Action {
		def void execute(IHighlightingSupport hs)

	}

	static class Highlight implements Action {
		protected List<? extends EObject> semanticElements
		protected HighlightingParameters highligtingParams

		new(EObject semanticElement, HighlightingParameters parameters) {
			this(Collections.singletonList(semanticElement), parameters)
		}

		new(List<? extends EObject> semanticElements, HighlightingParameters parameters) {
			this.semanticElements = semanticElements
			this.highligtingParams = parameters
		}

		override void execute(IHighlightingSupport hs) {
			hs.highlight(semanticElements, highligtingParams)
		}
	}

	static class HighlightingSupportNullImpl implements IHighlightingSupport {
		override void lockEditor() {
		}

		override boolean isLocked() {
			return false
		}

		override void releaseEditor() {
		}

		override void executeAsync(List<Action> actions) {
		}

		override void highlight(List<? extends EObject> semanticElement, HighlightingParameters parameters) {
		}
	}
}
