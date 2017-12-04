﻿$(document).ready(function () {

    function IsStringEmptyOrWhitespace(str) {
        return str.length === 0 || !str.trim();
    };
    // splits a string and converts it into a json object
    function SplitStringIntoJSON(str, separator)
    {
        var jsonobj = {};
        var strings = str.split(separator);
        var key = "";
        for (var s in strings)
        {
            if (IsStringEmptyOrWhitespace(strings[s]))
                continue;

            if (s % 2 === 0)
            {
                jsonobj[strings[s]] = "";
                key = strings[s];
            }
            else
            {
                jsonobj[key] = strings[s];
            }
        }

        return jsonobj;

    };

    function GenerateTableHTMLString(keypair)
    {
        var table = '<table>';
        var tr = "";
        var i = 0
        jQuery.each(keypair, function (name, value) {
            if (i === 0)
            {
                tr += '<thead><tr><td>' + name + '</td><td>' + value + '</td></tr></thead><tbody>';
            }
            else
            {
                tr += '<tr><td>' + name + '</td><td>' + value + '</td></tr>';
            }
            i += 1;
        });

        table += tr + "</tbody></table>";
        return table;
    };

    function DCSPosToMapPos(point, originpoint, ratio)
    {
        var xSignHandle = originpoint.X < 0 ? -1 : 1;
        var ySignHandle = originpoint.Y < 0 ? -1 : 1;
        var normalizedX = point.X - originpoint.X;
        var normalizedY = point.Y - originpoint.Y;
        var imagepoint = {}
        imagepoint.x = (normalizedX * xSignHandle) / ratio;
        imagepoint.y = (normalizedY * ySignHandle) / ratio;
        return imagepoint;
    }

    function RenderAirportsFirstTime(modelObj, rootImgPath) {
        $(modelObj.Airports).each(function (i) {
            var ImagePoint = DCSPosToMapPos(this.Pos, modelObj.Map.DCSOriginPosition, modelObj.Map.Ratio);
            var Img = rootImgPath + this.Image;
            var tooltipid = "tip_airport_content_id_" + this.ID;
            var id_attribute = 'data-airportID="' + this.ID + '"';
            var dot = $('<img ' + id_attribute + ' class="mrk" src="' + Img + '" width="32" height="32" originleft="' + ImagePoint.x +
                '" origintop="' + ImagePoint.y + '" data-tooltip-content="#' + tooltipid + '"' + '"/>');
            dot.css({
                position: 'absolute',
                left: ImagePoint.x + "px",
                top: ImagePoint.y + "px"
            });
            $(".mapcontent").append(dot);

            // Render the tooltip contents
            var content = "<strong>" + this.Name + "</strong><br/>";
            content += "Type: " + this.Type + "<br/>";
            content += "Status: " + this.Status + "<br/>";
            content += "<strong>Lat Long: " + this.LatLong + "</strong><br/>";
            content += "<strong>MGRS: " + this.MGRS + "</strong><br/><br/>";

            var tooltipspan = $('<div class="tooltip_templates" style="display: none"><span id="' + tooltipid + '" style="font-size: 10px" >' + content + '</span></div>');
            $(".mapcontent").append(tooltipspan);

        });
    };

    function RenderDepotsFirstTime(modelObj, rootImgPath)
    {
        $(modelObj.Depots).each(function (i) {
            var ImagePoint = DCSPosToMapPos(this.Pos, modelObj.Map.DCSOriginPosition, modelObj.Map.Ratio);
            var Img = rootImgPath + this.Image;
            var tooltipid = "tip_depot_content_id_" + this.ID;
            var id_attribute = 'data-depotID="' + this.ID + '"';
            var dot = $('<img ' + id_attribute + ' class="mrk" src="' + Img + '" width="32" height="32" originleft="' + ImagePoint.x +
                '" origintop="' + ImagePoint.y + '" data-tooltip-content="#' + tooltipid + '"' + '"/>');
            dot.css({
                position: 'absolute',
                left: ImagePoint.x + "px",
                top: ImagePoint.y + "px"
            });
            $(".mapcontent").append(dot);

            // Render the tooltip contents
            var content = "<strong>" + this.Name + "</strong><br/>";
            content += "Status: " + this.Status + "<br/>";
            content += "<strong>Lat Long: " + this.LatLong + "</strong><br/>";
            content += "<strong>MGRS: " + this.MGRS + "</strong><br/><br/>";

            var res = this.Resources.replace(/(?:\r\n|\r|\n)/g, '|');
            res = res.replace(/(?:  )/g, '');   // clean up the double spaces in the string

            res = res.substring(res.indexOf("|") + 1, res.length);  // remove the first part from the string (We dont need to show 'DWM - Depot')
            var capacity = res.substring(0, res.indexOf("|")) + '<br/>';   // get the overall capacity
            content += capacity;
            res = res.substring(res.indexOf("|") + 1, res.length);  // remove the capacity from the string
            var json_resources = SplitStringIntoJSON(res, "|");     // now we convert this string into a json object    
            content += GenerateTableHTMLString(json_resources);     // generate the html table from the json object
            //content += this.Resources.replace(/(?:\r\n|\r|\n)/g, '<br/>');
            var tooltipspan = $('<div class="tooltip_templates" style="display: none"><span id="' + tooltipid + '" style="font-size: 10px" >' + content + '</span></div>');
            $(".mapcontent").append(tooltipspan);

        });
    };

    function RenderCapturePointsFirstTime(modelObj, rootImgPath)
    {
        $(model.CapturePoints).each(function (i) {
            var ImagePoint = DCSPosToMapPos(this.Pos, modelObj.Map.DCSOriginPosition, modelObj.Map.Ratio);
            var Img = rootImgPath + this.Image;
            var tooltipid = "tip_cp_content_id_" + this.ID;
            var id_attribute = 'data-capturepointID="' + this.ID + '"';
            var dot = $('<img ' + id_attribute + ' class="mrk" src="' + Img + '" width="32" height="32" originleft="' + ImagePoint.x +
                '" origintop="' + ImagePoint.y + '" data-tooltip-content="#' + tooltipid + '"' + '"/>');
            dot.css({
                position: 'absolute',
                left: ImagePoint.x + "px",
                top: ImagePoint.y + "px"
            });
            $(".mapcontent").append(dot);

            var content = "<strong>" + this.Name + "</strong><br/>";
            content += "Status: " + this.Status + "<br/>";
            content += "<strong>Lat Long: " + this.LatLong + "</strong><br/>";
            content += "<strong>MGRS: " + this.MGRS + "</strong><br/><br/>";
            content += "Blue: " + this.BlueUnits + "<br/>";
            content += "Red: " + this.RedUnits + "<br/>";
            var tooltipspan = $('<div class="tooltip_templates" style="display: none"><span id="' + tooltipid + '" style="font-size: 10px" >' + content + '</span></div>');
            $(".mapcontent").append(tooltipspan);
        });
    };

    function RenderMapFirstTime(modelObj, rootImgPath)
    {
        var headingcontent = $("<h2>Server: " + modelObj.ServerName + "</h2></br><h><b>Status: " + modelObj.Status + "</b></h></br><h><b>Restarts In: " + modelObj.RestartTime + "</b></h>");
        $("#Heading").append(headingcontent);

        RenderAirportsFirstTime(modelObj, rootImgPath);
        RenderDepotsFirstTime(modelObj, rootImgPath);
        RenderCapturePointsFirstTime(modelObj, rootImgPath);

        $('.mrk').tooltipster({
            theme: 'tooltipster-noir'
        });      
    };

        
    

    RenderMapFirstTime(model, ROOT);


    // setup signalR
    $.connection.hub.logging = true;

    var GameHubProxy = $.connection.gameHub;    // apparently first letter is lowercase (signalr converts this)

    GameHubProxy.client.UpdateMarkers = function (modelObj) {
        $(modelObj.Depots).each(function (i) {
            var content = "<strong>" + this.Name + "</strong><br/>";
            content += "Status: " + this.Status + "<br/>";
            content += "<strong>Lat Long: " + this.LatLong + "</strong><br/>";
            content += "<strong>MGRS: " + this.MGRS + "</strong><br/><br/>";

            var res = this.Resources.replace(/(?:\r\n|\r|\n)/g, '|');
            res = res.replace(/(?:  )/g, '');   // clean up the double spaces in the string

            res = res.substring(res.indexOf("|") + 1, res.length);  // remove the first part from the string (We dont need to show 'DWM - Depot')
            var capacity = res.substring(0, res.indexOf("|")) + '<br/>';   // get the overall capacity
            content += capacity;
            res = res.substring(res.indexOf("|") + 1, res.length);  // remove the capacity from the string
            var json_resources = SplitStringIntoJSON(res, "|");     // now we convert this string into a json object    
            content += GenerateTableHTMLString(json_resources);     // generate the html table from the json object

            // locate the html content
            var img = $('[data-depotID=' + this.ID + ']');
            var tipspan = $('#tip_depot_content_id_' + this.ID);
            img.attr('src', ROOT + this.Image);
            tipspan.html(content);
        });
    };

    $.connection.hub.start().done(function ()
    {

        $(window).bind('beforeunload', function () {
            var GHubProxy = $.connection.gameHub;
            GHubProxy.server.unsubscribe(model.ServerID);
        });

        var GHubProxy = $.connection.gameHub;
        GHubProxy.server.subscribe(model.ServerID);
    });
    
    
    
        

    
});


$(document).ready(function () {
    $("#viewport").mapbox(
        {
            mousewheel: true,
            afterZoom: function (level, layer, xcoord, ycoord, totalWidth, totalHeight, viewport)
            {
                // xcoord and ycoord are the new left/top coordinates of the current image
                $(".mrk").each(function (i)
                {
                    var x = 0
                    var y = 0
                    if (totalHeight === null || totalHeight === undefined)
                    {
                        x = parseInt($(this).attr("originleft"))
                        y = parseInt($(this).attr("origintop"))
                    }
                    else
                    {
                        var ratio = totalHeight / viewport.offsetHeight
                        x = parseInt($(this).attr("originleft")) * ratio
                        y = parseInt($(this).attr("origintop")) * ratio
                    }
                    

                    //var x = parseInt($(this).css("left").replace("px", ""))
                    //var y = parseInt($(this).css("top").replace("px", ""))
                    
                    $(this).css({
                        position: 'absolute',
                        left: x + "px",
                        top: y + "px"
                    })
                    
                })
                

            }
        });
    $(".map-control a").click(function () { //control panel 
        var viewport = $("#viewport");
        // this.className is same as method to be called 
        if (this.className === "zoom" || this.className === "back") {
            viewport.mapbox(this.className, 2);//step twice 
        }
        else {
            viewport.mapbox(this.className);
        }
        return false;
    });
}); 