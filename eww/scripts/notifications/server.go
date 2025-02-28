package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/diamondburned/gotk4/pkg/gdkpixbuf/v2"
	"github.com/diamondburned/gotk4/pkg/glib/v2"
	"github.com/godbus/dbus/v5"
)

const (
	DBusName      = "org.freedesktop.Notifications"
	DBusPath      = "/org/freedesktop/Notifications"
	DBusInterface = "org.freedesktop.Notifications"
)

type Server struct {
	id        uint32
	dnd       bool
	conn      *dbus.Conn
	mutexLock sync.Mutex
}

type Notifications struct {
	Count         int                   `json:"count"`
	Notifications []NotificationDetails `json:"notifications"`
	Popups        []NotificationDetails `json:"popups"`
}

type NotificationDetails struct {
	ID      int        `json:"id"`
	App     string     `json:"app"`
	Summary string     `json:"summary"`
	Body    string     `json:"body"`
	Time    string     `json:"time"`
	Urgency int        `json:"urgency"`
	Actions [][]string `json:"actions"`
	Image   string     `json:"image"`
}

// ImageData matches the (iiibiiay) DBus signature for image data
type ImageData struct {
	Width         int32
	Height        int32
	RowStride     int32
	HasAlpha      bool
	BitsPerSample int32
	Channels      int32
	Data          []byte
}

func (s *Server) Notify(appName string, replacesId uint32, appIcon string, summary string, body string, actions []string, hints map[string]dbus.Variant, expireTimeout int32) (ret uint32, err *dbus.Error) {

	s.mutexLock.Lock()
	defer s.mutexLock.Unlock()

	notifications := s.ReadLogFile()

	// Define urgency
	var urgency any

	if urgencyHint, exists := hints["urgency"]; exists && urgencyHint.Value() != nil {
		urgency = urgencyHint.Value()
	}

	var urgencyVal int
	switch v := urgency.(type) {
	case uint32:
		urgencyVal = int(v)
	case uint8:
		urgencyVal = int(v)
	case int:
		urgencyVal = v
	default:
		urgencyVal = 1
	}

	if replacesId != 0 {
		s.id = replacesId
	} else {

		if len(notifications.Notifications) != 0 {
			s.id = uint32(notifications.Notifications[0].ID) + 1
		} else {
			s.id = 1
		}

	}

	actionList := make([][]string, 0)
	for i := 0; i < len(actions); i += 2 {
		actionList = append(actionList, []string{actions[i], actions[i+1]})
	}

	details := NotificationDetails{
		ID:      int(s.id),
		App:     appName,
		Summary: summary,
		Body:    body,
		Time:    time.Now().Format("15:04"),
		Urgency: urgencyVal,
		Actions: actionList,
		Image:   "",
	}

	imageUrl, imgErr := s.ExtractImage(hints)
	if imgErr != nil {
		fmt.Println(imgErr)
	}
	details.Image = imageUrl

	app_icon := strings.TrimSpace(appIcon)

	if app_icon != "" {
		if strings.HasPrefix(app_icon, "file://") {
			details.Image = app_icon[7:]
			fmt.Println(app_icon[7:])
		} else if strings.HasPrefix(app_icon, "/") {
			details.Image = app_icon
		} else {
			details.Image = ""
		}
	}

	newNotifications := make([]NotificationDetails, len(notifications.Notifications))
	copy(newNotifications, notifications.Notifications)
	notifications.Notifications = append([]NotificationDetails{details}, newNotifications...)

	s.SaveNotifications(notifications)
	if !s.dnd {
		s.SavePopup(details)
	}

	dnd_state, _ := json.Marshal(s.dnd)
	fmt.Printf("Got notifications from %s\n", appName)
	fmt.Printf("==== %s ====\n", summary)
	fmt.Println(body)
	fmt.Println(appIcon)
	fmt.Println(urgencyVal)
	fmt.Println(time.Now().Format("15:04"))
	fmt.Println(string(dnd_state))
	fmt.Println(hints["desktop-entry"])
	fmt.Println(hints["sound-file"])
	fmt.Println(s.ExtractImage(hints))
	fmt.Printf("==== END %s ====\n\n", summary)

	return s.id, nil
}

func (s Server) GetServerInformation() (string, string, string, string, *dbus.Error) {
	return "Notification Server", "notifications", "1.0", "1.2", nil
}

func (s Server) GetServerCapabilities() ([]string, *dbus.Error) {
	return []string{"actions", "body", "body-hyperlinks", "body-markup", "icon-static", "persistence", "sound"}, nil
}

func (s Server) ActionInvoked(id uint32, action string) {

	err := s.conn.Emit(dbus.ObjectPath(DBusPath), DBusInterface+".ActionInvoked", id, action)
	if err != nil {
		fmt.Println("Failed to emit ActionInvoked signal: %v", err)
	}
	fmt.Println("ActionInvoked")
}

func (s Server) InvokeAction(id uint32, action string) {
	s.ActionInvoked(id, action)
}

func (s Server) NotificationClosed(id uint32, reason uint32) {
	err := s.conn.Emit(dbus.ObjectPath(DBusPath), DBusInterface+".NotificationClosed", id, reason)
	if err != nil {
		fmt.Println("Failed to emit NotificationClosed signal: %v", err)
	}
}

func (s *Server) CloseNotification(id uint32) *dbus.Error {
	allNotifications := s.ReadLogFile()
	filteredNotifications := []NotificationDetails{}
	for _, notification := range allNotifications.Notifications {
		if notification.ID != int(id) {
			filteredNotifications = append(filteredNotifications, notification)
		}
	}

	filteredPopups := []NotificationDetails{}
	for _, popup := range allNotifications.Popups {
		if popup.ID != int(id) {
			filteredPopups = append(filteredPopups, popup)
		}
	}

	allNotifications.Notifications = filteredNotifications
	allNotifications.Popups = filteredPopups
	fmt.Println("Notification Closed")
	s.WriteLogFile(allNotifications)
	s.NotificationClosed(id, 2)
	return nil
}

func (s *Server) ToggleDND() *dbus.Error {
	s.dnd = !s.dnd
	s.GetDNDState()
	return nil
}

func (s *Server) GetDNDState() (bool, *dbus.Error) {
	dnd_state, _ := json.Marshal(s.dnd)
	fmt.Println(dnd_state)
	cmd := exec.Command("eww", "update", fmt.Sprintf("do_not_disturb=%s", string(dnd_state)))
	cmd.Run()
	return s.dnd, nil
}

func (s Server) ReadLogFile() Notifications {

	notification_log_path := s.GetNotifCachePath()

	notif_log_data, notif_path_err := os.ReadFile(notification_log_path)
	if notif_path_err != nil {
		emptyNotification := Notifications{
			Count:         0,
			Notifications: []NotificationDetails{},
			Popups:        []NotificationDetails{},
		}
		output, _ := json.MarshalIndent(emptyNotification, "", "  ")
		os.WriteFile(notification_log_path, output, 0644)
	}
	var allNotifications Notifications
	err := json.Unmarshal(notif_log_data, &allNotifications)
	if err != nil {
		fmt.Println("Marshalling failed\n \t- %s", err)
	}

	return allNotifications
}

func (s Server) GetNotifCachePath() string {

	cache_path, path_err := os.UserCacheDir()
	if path_err != nil {
		panic(path_err)
	}
	notification_log_path := filepath.Join(cache_path, "notifications.json")

	return notification_log_path
}

func (s Server) GetNotifImageCachePath() string {

	cache_path, path_err := os.UserCacheDir()
	if path_err != nil {
		panic(path_err)
	}
	notification_image_dir := filepath.Join(cache_path, "notify_img_data")

	if _, err := os.Stat(notification_image_dir); os.IsExist(err) {
		err := os.Mkdir(notification_image_dir, 0755)
		if err != nil {
			panic(err)
		}
	}
	return notification_image_dir
}

func (s Server) WriteLogFile(notifications Notifications) {
	allNotifications := s.ReadLogFile()
	writeData := Notifications{
		Count:         len(allNotifications.Notifications),
		Notifications: notifications.Notifications,
		Popups:        notifications.Popups,
	}

	jsonOutput, _ := json.MarshalIndent(writeData, "", "  ")
	cmd := exec.Command("eww", "update", fmt.Sprintf("notifications=%s", string(jsonOutput)))
	cmd.Run()
	os.WriteFile(s.GetNotifCachePath(), jsonOutput, 0200)
}

func (s Server) SaveNotifications(notifications Notifications) {

	s.WriteLogFile(notifications)
}

func (s Server) SavePopup(data NotificationDetails) *dbus.Error {

	allNotifications := s.ReadLogFile()

	for _, popup := range allNotifications.Popups {
		if popup.ID == data.ID {
			return &dbus.Error{
				Name: "org.freedesktop.Notifications.PopupExists",
			}
		}
	}
	if len(allNotifications.Popups) >= 3 {
		allNotifications.Popups = allNotifications.Popups[1:]
	}

	allNotifications.Popups = append(allNotifications.Popups, data)
	s.WriteLogFile(allNotifications)

	if data.Urgency != 2 {
		go func(popupId int) {
			time.Sleep(5 * time.Second)
			s.DismissPopup(popupId)
		}(data.ID)
	}

	return nil
}

func (s Server) DismissPopup(popupId int) *dbus.Error {
	allNotifications := s.ReadLogFile()
	activePopups := []NotificationDetails{}

	for _, current := range allNotifications.Popups {
		if current.ID != popupId {
			activePopups = append(activePopups, current)
		}
	}

	allNotifications.Popups = activePopups
	s.WriteLogFile(allNotifications)
	return nil
}

func (s Server) ClearAll() *dbus.Error {
	notifications := s.ReadLogFile()
	for _, notify := range notifications.Notifications {
		s.NotificationClosed(uint32(notify.ID), 2)
	}

	notifications = Notifications{
		Count:         0,
		Notifications: []NotificationDetails{},
		Popups:        []NotificationDetails{},
	}

	s.WriteLogFile(notifications)
	return nil
}

func (s Server) GetCurrent() (Notifications, *dbus.Error) {
	notifications := s.ReadLogFile()
	jsonOutput, _ := json.MarshalIndent(notifications, "", "  ")
	cmd := exec.Command("eww", "update", fmt.Sprintf("notifications=%s", string(jsonOutput)))
	cmd.Run()
	return notifications, nil
}

func (s *Server) ExtractImage(hint map[string]dbus.Variant) (string, error) {
	if imageData, exists := hint["image-data"]; exists {
		if data, ok := imageData.Value().([]interface{}); ok {
			if len(data) != 7 {
				return "", fmt.Errorf("Invalid image length: expected 7 got %d", len(data))
			}

			imgData := ImageData{
				Width:         data[0].(int32),
				Height:        data[1].(int32),
				RowStride:     data[2].(int32),
				HasAlpha:      data[3].(bool),
				BitsPerSample: data[4].(int32),
				Channels:      data[5].(int32),
				Data:          data[6].([]byte),
			}

			return s.ConvertToPng(imgData)
		}
		return "", fmt.Errorf("invalid image data format")
	}
	// Check for image-path as fallback
	if imagePath, exists := hint["image-path"]; exists {
		if path, ok := imagePath.Value().(string); ok {
			return path, nil
		}
	}

	return "", nil
}

// Converts the Image Data from Dbus into a usable file format.
func (s *Server) ConvertToPng(imgData ImageData) (string, error) {
	imgPath := filepath.Join(s.GetNotifImageCachePath(), fmt.Sprintf("%d.png", s.id))
	var image = gdkpixbuf.NewPixbufFromBytes(glib.NewBytes(imgData.Data), gdkpixbuf.ColorspaceRGB, imgData.HasAlpha, int(imgData.BitsPerSample), int(imgData.Width), int(imgData.Height), int(imgData.RowStride))
	err := image.Savev(imgPath, "png", nil, nil)
	if err != nil {
		return "", fmt.Errorf("Failed to save image: %v", err)
	}

	return imgPath, nil
}

func main() {
	fmt.Println("Starting notification server...")
	conn, err := dbus.SessionBus()
	if err != nil {
		panic(err)
	}
	fmt.Println("Requesting DBus name...")
	reply, err := conn.RequestName(DBusName, dbus.NameFlagDoNotQueue)
	if err != nil {
		panic(err)
	}
	if reply != dbus.RequestNameReplyPrimaryOwner {
		panic("Name already taken")
	}
	fmt.Println("Successfully acquired name...")
	s := &Server{id: 0, dnd: false, conn: conn}
	path := dbus.ObjectPath(DBusPath)

	conn.Export(s, path, DBusInterface)

	select {}
}
