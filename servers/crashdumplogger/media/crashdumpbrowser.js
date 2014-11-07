/*! crashdumpbrowser.js | Crashdump Browser | Adam Perry | opensource.org/licenses/MIT */
/*jslint plusplus: true, indent: 3, browser: true*/
(function ($) {
   "use strict";
   function showView(id) {
      if (typeof id === "object") {
         id = $(id.target).data("show");
      }
      $(".view:visible").not("#" + id).slideUp();
      $("#" + id).not(":visible").slideDown();
   }

   function changePage(e) {
      var target = $(e.srcElement || e.target), page;
      page = target.data("page");
      if (target.parents("#overview").length) {
         $("#overviewTable").data("page", page);
         loadGrid();
      } else {
         $("#errorTable").data("page", page);
         loadError();
      }
   }

   function showPagination(e, data) {
      var start, end, pages;
      e.html("");
      if (data === undefined || data.total === undefined || data.page === undefined || data.perPage === undefined) {
         return false;
      }
      start = parseInt(data.page) * parseInt(data.perPage) + 1;
      end = Math.min(parseInt(data.total), start + parseInt(data.perPage) - 1);
      pages = Math.ceil(parseInt(data.total) / parseInt(data.perPage));
      if (parseInt(data.page) > 0) {
         $('<a href="javascript:">&lt;</a>').data("page", parseInt(data.page) - 1).click(changePage).appendTo(e);
      }
      e.append(" " + start + " - " + end + " of " + data.total + " ");
      if (parseInt(data.page) < pages - 1) {
         $('<a href="javascript:">&gt;</a>').data("page", parseInt(data.page) + 1).click(changePage).appendTo(e);
      }
      e.data("page", data.page);
   }

   function populateTable(id, data) {
      var i, j, rowdata, row;
      $("#" + id + " tr.row").remove();
      if (data && data.rows) {
         for (i = 0; i < data.rows.length; ++i) {
            if (typeof data.rows[i] === "object") {
               rowdata = data.rows[i];
               row = $('<tr class="row" id="row' + i + '"/>');
               if (data.col1 !== undefined) {
                  $('<td/>').html(data.col1).appendTo(row);
               }
               if (data.col2 !== undefined) {
                  $('<td/>').html(data.col2).appendTo(row);
               }
               for (j = 0; j < rowdata.length; ++j) {
                  if (rowdata[j] !== undefined) {
                     $('<td/>').addClass("detail").html(rowdata[j]).appendTo(row);
                  } else {
                     $('<td/>').addClass("detail").html("Error").appendTo(row);
                  }
               }
               row.appendTo($("#" + id + " tbody"));
            }
         }
         $("#" + id + " tr.row:even").addClass("light");
         showView(id);
      }
      $("body").removeClass("loading");
   }

   function showDetail(data) {
      populateTable("detailView", data);
   }

   function showError(data) {
      populateTable("errorView", data);
      showPagination($("#errorView .pagination"), data);
   }

   function showGrid(data) {
      populateTable("overview", data);
      showPagination($("#overview .pagination"), data);
   }

   function loadDetail(e) {
      var row = $(e.srcElement || e.target).parents("tr"), data = { "id": row.children("td:eq(0)").html() };
      $("body").addClass("loading");
      $.ajax({ "url": "api/detail.php", "data": data, "dataType": "json", "success": showDetail });
   }

   function loadError(e) {
      var target, row, data = { "minversion": $("#errorMinVersion").val(), "maxversion": $("#errorMaxVersion").val(), "sort": $("#overviewTable").data("sort"), "dir": $("#overviewTable").data("dir"), "page": $("#errorTable").data("page") };
      if (e === undefined) {
         data.id = target.data("error");
      } else {
         target = $(e.srcElement || e.target);
         if (!target.is("input[type=submit]")) {
            row = target.parents("tr");
            data.id = row.children("td:eq(2)").html();
            $("#filterError").data("error", row.children("td:eq(2)").html());
            $("#errorView h2").text('Crash reports for "' + row.children("td:eq(6)").text() + ' in ' + row.children("td:eq(8)").text() + ' (' + row.children("td:eq(7)").text() + ')"');
         } else {
            data.id = target.data("error");
         }
      }
      $("#errorTable").data("page", 0);
      $("body").addClass("loading");
      $.ajax({ "url": "api/error.php", "data": data, "dataType": "json", "success": showError });
   }

   function loadGrid() {
      var data = { "project": $("#projSelect").val(), "status": $("select[name=status]").val(), "minversion": $("#overviewMinVersion").val(), "maxversion": $("#overviewMaxVersion").val(), "mincount": $("#minCount").val(), "maxcount": $("#maxCount").val(), "exception": $("[name=exception]").val(), "file": $("[name=file]").val(), "function": $("[name=function]").val(), "sort": $("#overviewTable").data("sort"), "dir": $("#overviewTable").data("dir"), "page": $("#overviewTable").data("page") };
      localStorage.setItem("projectId", data.project);
      $("#overviewTable").data("page", 0);
      $("body").addClass("loading");
      $.ajax({ "url": "api/grid.php", "data": data, "dataType": "json", "success": showGrid });
   }

   function generateTestReport(e) {
      e.preventDefault();
      $.ajax({ "url": "api/test.php", "success": loadGrid });
   }

   function checkAll(e) {
      var element = $(e.srcElement || e.target);
      if (element.data("checked") === 1) {
         element.parents("table").find("[type=checkbox]:checked").not(".topCheck").click();
         element.data("checked", 0);
      } else {
         element.parents("table").find("[type=checkbox]").not(".topCheck,:checked").click();
         element.data("checked", 1);
      }
   }

   function sortTable(e) {
      var element = $(e.srcElement || e.target), table = element.parents("table");
      table.data("sort", element.data("sort"));
      if (element.is(".sortDown")) {
         element.removeClass("sortDown").addClass("sortUp");
         table.data("dir", "ASC");
      } else {
         element.parent().children().removeClass("sortUp").removeClass("sortDown");
         element.addClass("sortDown");
         table.data("dir", "DESC");
      }
      if (table.is("#overviewTable")) {
         loadGrid();
      } else if (table.is("#errorTable")) {
         loadError();
      }
   }

   function syncField(e) {
      var element = $(e.srcElement || e.target);
      $("[data-sync=" + element.data("sync") + "]").val(element.val());
   }

   function chooseSimilar(e) {
      var element = $(e.srcElement || e.target);
      $("#main").removeClass("fade");
      $("#similarContainer").fadeOut();
      if (element.is("#similarCancel")) {
         return false;
      } else if (element.is("#similarSubmit")) {
         performAction($("#similarList").data("id"), $("#similarId").val());
      } else {
         performAction($("#similarList").data("id"), element.val());
      }
   }

   function showSimilar() {
      $("#main").addClass("fade");
      $("#similarContainer").fadeIn();
   }

   function actionCallback(data) {
      var i, line, similar;
      $("body").removeClass("loading");
      $("#overviewBulk").val("");
      if (typeof data.similar === "object" && data.similar.length) {
         // Show similar errors
         $("#similarList").html("").data("id", data.id);
         for (var i = 0; i < data.similar.length && i < 10; ++i) {
            similar = data.similar[i];
            line = $("<div/>").addClass("similar");
            line.append($("<input/>").attr("type", "submit").attr("value", similar.id));
            line.append(similar.exception + " in " + similar["function"] + " (" + similar.file + ")");
            line.appendTo($("#similarList"));
         }
         showSimilar();
      } else if (typeof data.similar === "object") {
         // No similar errors, but show the interface anyway
         $("#similarList").html("<b>No similar errors found.</b> You may want to double-check that this is actually a duplicate.").data("id", data.id);
         showSimilar();
      } else {
         $("#overviewTable").data("page", $("#overview .pagination").data("page")); // Retain pagination
         loadGrid();
      }
   }

   function performAction(e, d) {
      var select = $(e.srcElement || e.target), data = { "status": select.find("option:selected").val() };
      if (d === undefined) {
         if (select.parents("tr").length) {
            data.id = select.parents("tr").children("td:eq(2)").html();
         } else {
            data.id = new Array();
            $("#overviewTable input:checked").each(function(i, e) {
               data.id.push($(e).parents("tr").children("td:eq(2)").html());
            });
         }
      } else {
         data.duplicateid = d;
         data.id = e;
         data.status = 5;
      }
      $("body").addClass("loading");
      $.ajax({ "url": "api/action.php", "data": data, "dataType": "json", "success": actionCallback });
   }

   function init() {
      var projectId = "";
      if (localStorage !== undefined && localStorage.getItem("projectId")) {
         projectId = localStorage.getItem("projectId");
         $("#projSelect").val(projectId);
      }
      $(document).delegate("#projSelect", "change", loadGrid);
      $(document).delegate("#filterGrid", "click", loadGrid);
      $(document).delegate("#filterError", "click", loadError);
      $(document).delegate("#overview td.detail", "click", loadError);
      $(document).delegate("#errorView td.detail", "click", loadDetail);
      $(document).delegate("#testReport input", "click", generateTestReport);
      $(document).delegate("#similarBox input[type=submit]", "click", chooseSimilar);
      $(document).delegate("a[data-show]", "click", showView);
      $(document).delegate(".sortable", "click", sortTable);
      $(document).delegate(".topCheck", "click", checkAll);
      $(document).delegate("[data-sync]", "change", syncField);
      $(document).delegate("table select, #overviewBulk", "change", performAction);
      loadGrid();
   }

   $(init);
}(jQuery));