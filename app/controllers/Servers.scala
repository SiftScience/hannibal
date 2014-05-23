/*
 * Copyright 2014 YMC. See LICENSE for details.
 */

package controllers

import play.api.mvc._
import views.html.{servers => html}

object Servers extends Controller {
  def index = Action { implicit request =>
    Ok(html.index())
  }
}