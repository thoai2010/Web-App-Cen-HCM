using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;

namespace QLBH
{
    public class MvcApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();
            RouteConfig.RegisterRoutes(RouteTable.Routes);
        }

        protected void Session_Start()
        {
            if (Session["Cart"] == null)
                Session["Cart"] = new List<QLBH.Models.CartItem>();

            if (Session["WishList"] == null)
                Session["WishList"] = new List<QLBH.Models.YeuThichItem>();
        }
    }
}
