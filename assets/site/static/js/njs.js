function toggleCgiFootMore() {
    var menuDialog = document.querySelector(".menuDialog");
    if (menuDialog) {
        menuDialog.style.display = menuDialog.style.display === 'none' ? '' : 'none';
    }
}

function historyBack() {
    var ref = document.referrer;
    if (ref.length > 0) {
        window.history.back(-1);
    } else {
        window.location.href = "/"
    }
}

var theBall = function () {
    function theBallOp(position, condition) {
        var index = 0;
        if (position.length > 0) index = 1;
        if (condition.length > 0) index = 2;
        if (condition.length > 0 && position.length > 0) index = 3;

        var balls = document.querySelectorAll(".ball");
        balls.forEach(function(ball) {
            ball.classList.remove("opacityOne");

            if (index > 0) {
                ball.classList.add("opacityOne");

                if (index === 1) {
                    for (var i = 0; i < position.length; i++) {
                        if (position[i] === ball.getAttribute("data-index")) {
                            ball.classList.remove("opacityOne");
                        }
                    }
                }

                if (index === 2) {
                    for (var i = 0; i < condition.length; i++) {
                        if (condition[i] === ball.getAttribute("data-name")) {
                            ball.classList.remove("opacityOne");
                        }
                    }
                }

                if (index === 3) {
                    for (var i = 0; i < position.length; i++) {
                        if (position[i] === ball.getAttribute("data-index")) {
                            ball.classList.remove("opacityOne");
                            ball.classList.add("opacityOne");

                            for (var o = 0; o < condition.length; o++) {
                                if (condition[o] === ball.getAttribute("data-name")) {
                                    ball.classList.remove("opacityOne");
                                }
                            }
                        }
                    }
                }
            }
        });
    }

    var positionList = [], conditionList = [];

    // 绑定选择器点击事件
    document.addEventListener('click', function(e) {
        if (e.target && e.target.classList.contains('choose_superior')) {
            // 切换active状态
            e.target.classList.toggle('active');

            // 更新选中的选项
            updateSelectedOptions();
        }
    });

    // 更新选中的选项
    function updateSelectedOptions() {
        var list = [], lists = [];

        // 收集所有激活的选项
        var activeOptions = document.querySelectorAll(".choose_superior.active");
        activeOptions.forEach(function(el) {
            var value = el.getAttribute("data-value");
            // 判断是数字还是生肖
            if (!isNaN(value) && value !== '') {
                list.push(value);
            } else {
                lists.push(value);
            }
        });

        positionList = list;
        conditionList = lists;
        theBallOp(positionList, conditionList);
    }

    // 绑定还原按钮点击事件
    var reductions = document.querySelectorAll(".reduction");
    reductions.forEach(function(element) {
        element.addEventListener('click', function(e) {
            e.stopPropagation();
            var index = parseInt(this.value);

            // 找到按钮所在的组
            var group = this.closest('.choice-input');

            if (group) {
                // 清空对应组的active状态
                group.querySelectorAll(".choose_superior").forEach(function(el) {
                    el.classList.remove("active");
                });

                // 更新对应的列表
                if (index === 0) {
                    positionList = [];
                } else {
                    conditionList = [];
                }

                theBallOp(positionList, conditionList);
            }
        });
    });

    // 绑定年份更多点击事件
    var yearMore = document.querySelector(".yearMore");
    if (yearMore) {
        yearMore.addEventListener('click', function() {
            var yearDialog = document.querySelector(".yearDialog");
            if (yearDialog) {
                yearDialog.style.display = yearDialog.style.display === 'none' ? '' : 'none';
            }
        });
    }
}

// 动态加载脚本
document.addEventListener('DOMContentLoaded', function() {
    var scripts = document.querySelectorAll('script[data-url]');
    scripts.forEach(function(script) {
        var url = script.getAttribute('data-url');
        script.src = url;
    });
});

// 设置全局变量
window.getType = "am";

// 初始化theBall
document.addEventListener('DOMContentLoaded', function() {
    theBall();
});


// 判断当前页面是否在 iframe 内
const inIframe = window.self !== window.top;

// 首次 DOM 加载后上报高度
document.addEventListener("DOMContentLoaded", function () {
    if (inIframe) {
        reportHeight();
    }
});

// 窗口尺寸变化时上报（如字体变化、布局变化等）
window.addEventListener("resize", function () {
    if (inIframe) {
        reportHeight();
    }
});

// 主动向父页面报告高度
function reportHeight() {
    let height = document.body.scrollHeight;
    if(!height){
        height = document.documentElement.scrollHeight;
    }
    window.parent.postMessage(
        { type: "setHeight", height },
        "*" // 如需安全限制可替换为父页面域名
    );
}



//========more
// 在页面底部添加以下代码
(function() {
    // 使用一个标记来跟踪对话框状态
    var dialogVisible = false;
    
    // 初始化：确保对话框隐藏
    function init() {
        var dialog = document.querySelector('.yearDialog');
        if (dialog) {
            dialog.style.display = 'none';
            dialogVisible = false;
        }
    }
    
    // 页面加载完成后初始化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
    
    // 点击事件处理
    document.addEventListener('click', function(e) {
        // 如果点击了更多按钮
        if (e.target.classList.contains('yearMore')) {
            var dialog = document.querySelector('.yearDialog');
            if (dialog) {
                e.preventDefault();
                
                // 切换显示状态
                if (!dialogVisible) {
                    dialog.style.display = 'block';
                    dialogVisible = true;
                } else {
                    dialog.style.display = 'none';
                    dialogVisible = false;
                }
                
                // 阻止事件冒泡，避免影响其他地方
                e.stopPropagation();
                return false;
            }
        }
        
        // 如果点击了其他地方且对话框是显示的
        if (dialogVisible) {
            var dialog = document.querySelector('.yearDialog');
            var moreBtn = document.querySelector('.yearMore');
            
            // 检查点击是否在对话框或更多按钮之外
            if (dialog && 
                !dialog.contains(e.target) && 
                e.target !== moreBtn) {
                dialog.style.display = 'none';
                dialogVisible = false;
            }
        }
    });
})();